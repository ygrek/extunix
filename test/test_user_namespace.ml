
open ExtUnix.All

let mount_inside ~dir ~src ~tgt ?(fstype="") ~flags ?(option="") () =
  let tgt = Filename.concat dir tgt in
  if not (Sys.file_exists tgt) then Unix.mkdir tgt 0o640;
  mount src tgt fstype flags option

let mount_base dir =
  mount_inside ~dir ~src:"proc" ~tgt:"proc" ~fstype:"proc"
    ~flags:[MS_NOSUID; MS_NOEXEC; MS_NODEV] ();
  mount_inside ~dir ~src:"/sys" ~tgt:"sys" ~flags:[MS_BIND; MS_REC] ();
  mount_inside ~dir ~src:"/dev" ~tgt:"dev" ~flags:[MS_BIND; MS_REC] ();

  mount_inside ~dir ~src:"tmpfs" ~tgt:"dev/shm" ~fstype:"tmpfs"
    ~flags:[MS_NOSUID; MS_STRICTATIME; MS_NODEV]
    ~option:"mode=1777" ();

  mount_inside ~dir ~src:"tmpfs" ~tgt:"run" ~fstype:"tmpfs"
    ~flags:[MS_NOSUID; MS_STRICTATIME; MS_NODEV]
    ~option:"mode=755" ()

let do_chroot dest =
  Sys.chdir dest;
  chroot ".";
  Sys.chdir "/"

let test_userns_availability () =
  let unpriviledge_userns_clone =
    "/proc/sys/kernel/unprivileged_userns_clone" in
  if Sys.file_exists unpriviledge_userns_clone then begin
    let c = open_in unpriviledge_userns_clone in
    let v = input_line c in
    close_in c;
    if v <> "1" then begin
      Printf.eprintf "This kernel is configured to disable unpriviledge user\
                      namespace: %s must be 1\n" unpriviledge_userns_clone;
      exit 1
    end
  end

let open_out_string file towrite =
  try
    let cout = open_out file in
    output_string cout towrite;
    close_out cout
  with _ -> Printf.eprintf "Error during write of %s in %s\n" towrite file;
    exit 1

let mapusertoroot pid =
  open_out_string (pid "/proc/%i/setgroups") "deny";
  open_out_string (pid "/proc/%i/uid_map") "0 1000 1";
  open_out_string (pid "/proc/%i/gid_map") "0 1000 1"

let uidmap = 100000

let command ?(error=(fun () -> ())) fmt =
  Printf.ksprintf (fun cmd ->
      let c = Sys.command cmd in
      if c <> 0 then begin
        Printf.printf "Error during: %s\n%!" cmd;
        error ();
        exit 1
      end
    ) fmt

let set_usermap pid =
  let sprpid s = (Printf.sprintf s pid) in
  open_out_string (sprpid "/proc/%i/setgroups") "deny";
  if false
  then begin
    open_out_string (sprpid "/proc/%i/uid_map") "0 1000 1";
    open_out_string (sprpid "/proc/%i/gid_map") "0 1000 1"
  end
  else begin
    Printf.printf "pid: %i, mine: %i\n%!" pid (Unix.getpid ());
    let error () = ignore (Unix.kill pid 9) in
    command ~error "newuidmap %i 0 %i 1010" pid uidmap;
    command ~error "newgidmap %i 0 %i 1010" pid uidmap;
  end

let goto_child ~exec_in_parent =
  let fin,fout = Unix.pipe () in
  match Unix.fork () with
  | -1 -> Printf.printf "Fork failed\n%!"; exit 1
  | 0 -> (** child *)
    Unix.close fout;
    ignore (Unix.read fin (Bytes.create 1) 0 1);
    Unix.close fin
  | pid ->
    Unix.close fin;
    (exec_in_parent pid: unit);
    ignore (Unix.write fout (Bytes.create 1) 0 1);
    Unix.close fout;
    let _, status = Unix.waitpid [] pid in
    match status with
    | Unix.WEXITED s -> exit s
    | Unix.WSIGNALED s -> Unix.kill (Unix.getpid ()) s; assert false
    | Unix.WSTOPPED _ -> assert false

let exec_in_child (type a) f =
  let fin,fout = Unix.pipe () in
  match Unix.fork () with
  | -1 -> Printf.printf "Fork failed\n%!"; exit 1
  | 0 -> (** child *)
    Unix.close fout;
    let cin = Unix.in_channel_of_descr fin in
    let arg = (Marshal.from_channel cin : a) in
    close_in cin;
    f arg;
    exit 0
  | pid ->
    Unix.close fin;
    let cout = Unix.out_channel_of_descr fout in
    let call_in_child (arg:a) =
      Marshal.to_channel cout arg [];
      close_out cout;
      let _, status = Unix.waitpid [] pid in
      match status with
      | Unix.WEXITED 0 -> ()
      | Unix.WEXITED s -> exit s
      | Unix.WSIGNALED s -> Unix.kill (Unix.getpid ()) s; assert false
      | Unix.WSTOPPED _ -> assert false
    in
    call_in_child


let just_goto_child () =
  match Unix.fork () with
  | -1 -> Printf.printf "Fork failed\n%!"; exit 1
  | 0 -> (** child *) ()
  | pid ->
    let _, status = Unix.waitpid [] pid in
    match status with
    | Unix.WEXITED s -> exit s
    | Unix.WSIGNALED s -> Unix.kill (Unix.getpid ()) s; assert false
    | Unix.WSTOPPED _ -> assert false


let main () =
  let dir = Sys.argv.(1) in
  test_userns_availability ();
  (** the usermap can be set only completely outside namespaces,
      so we keep a child for doing that *)
  let call_set_usermap = exec_in_child set_usermap in
  unshare [ CLONE_NEWNS;
            CLONE_NEWIPC;
            CLONE_NEWPID;
            CLONE_NEWUTS;
            CLONE_NEWUSER;
          ];
  (** only the grand-child will be in the new pid namespace, the child is in an
      intermediary state not interesting *)
  goto_child ~exec_in_parent:call_set_usermap;
  Printf.printf "User: %i (%i)\n%!" (Unix.getuid ()) (Unix.geteuid ());
  Printf.printf "Pid: %i\n%!" (Unix.getpid ());
  Printf.printf "User: %i (%i)\n%!" (Unix.getuid ()) (Unix.geteuid ());
  (** make the mount private and mount basic directories *)
  mount_base dir;
  (** chroot in the directory *)
  do_chroot dir;
  (* let root_dir = Sys.readdir "/" in *)
  (* Array.iter (Printf.printf "%s\n%!") root_dir; *)
  setresuid 1000 1000 1000;
  setresgid 1000 1000 1000;
  Printf.printf "User: %i (%i)\n%!" (Unix.getuid ()) (Unix.geteuid ());
  Unix.execv "/bin/bash" [| "bash" |]


let () = Unix.handle_unix_error main ()
