
open ExtUnix.All

let mkdir ?(perm=0o750) dir =
  if not (Sys.file_exists dir) then Unix.mkdir dir perm

let mount_inside ~dir ~src ~tgt ?(fstype="") ~flags ?(data="") () =
  let tgt = Filename.concat dir tgt in
  mkdir tgt;
  mount ~source:src ~target:tgt ~fstype flags ~data

let mount_base dir =
  mount_inside ~dir ~src:"proc" ~tgt:"proc" ~fstype:"proc"
    ~flags:[MS_NOSUID; MS_NOEXEC; MS_NODEV] ();
  mount_inside ~dir ~src:"/sys" ~tgt:"sys" ~flags:[MS_BIND; MS_REC] ();
  mount_inside ~dir ~src:"/dev" ~tgt:"dev" ~flags:[MS_BIND; MS_REC] ();

  mount_inside ~dir ~src:"tmpfs" ~tgt:"dev/shm" ~fstype:"tmpfs"
    ~flags:[MS_NOSUID; MS_STRICTATIME; MS_NODEV]
    ~data:"mode=1777" ();

  mount_inside ~dir ~src:"tmpfs" ~tgt:"run" ~fstype:"tmpfs"
    ~flags:[MS_NOSUID; MS_STRICTATIME; MS_NODEV]
    ~data:"mode=755" ();

  (** for aptitude *)
  mkdir (Filename.concat dir "/run/lock")

let do_chroot dest =
  Sys.chdir dest;
  chroot ".";
  Sys.chdir "/"

let read_in_file fmt =
  Printf.ksprintf (fun file ->
      let c = open_in file in
      let v = input_line c in
      close_in c;
      v
    ) fmt


let test_userns_availability () =
  let unpriviledge_userns_clone =
    "/proc/sys/kernel/unprivileged_userns_clone" in
  if Sys.file_exists unpriviledge_userns_clone then begin
    let v = read_in_file "%s" unpriviledge_userns_clone in
    if v <> "1" then begin
      Printf.eprintf "This kernel is configured to disable unpriviledge user\
                      namespace: %s must be 1\n" unpriviledge_userns_clone;
      exit 1
    end
  end

let write_in_file fmt =
  Printf.ksprintf (fun file ->
      Printf.ksprintf (fun towrite ->
          try
            let cout = open_out file in
            output_string cout towrite;
            close_out cout
          with _ ->
            Printf.eprintf "Error during write of %s in %s\n"
              towrite file;
            exit 1
        )
    ) fmt

let command fmt = Printf.ksprintf (fun cmd -> Sys.command cmd = 0) fmt

let command_no_fail ?(error=(fun () -> ())) fmt =
  Printf.ksprintf (fun cmd ->
      let c = Sys.command cmd in
      if c <> 0 then begin
        Printf.eprintf "Error during: %s\n%!" cmd;
        error ();
        exit 1;
      end
    ) fmt

(** {2 GPG} *)

let download_keyid = "0xBAEFF88C22F6E216"
let download_keyserver = "hkp://pool.sks-keyservers.net"

type gpg_t =
  | GPGNotAvailable
  | GPGAvailable of string


let gpg_setup ~dir =
  let command_raise fmt =
    Printf.ksprintf (fun cmd ->
        Printf.ksprintf (fun msg ->
            let c = Sys.command cmd in
            if c <> 0 then begin
              Printf.eprintf "%s\n%!" msg;
              raise Exit
            end
          )
      ) fmt
  in
  try
    command_raise
      "which gpg >/dev/null 2>&1"
      "The program gpg is not present: can't validate download";
    let gpg_dir = Filename.concat dir "gpg" in
    mkdir ~perm:0o700 gpg_dir;
    command_raise
      "GNUPGHOME=%S gpg --keyserver %s --recv-keys %s > /dev/null 2>&1;"
      gpg_dir download_keyserver download_keyid
      "Can't download gpg key data: can't validate download";
    GPGAvailable gpg_dir
  with Exit ->
    GPGNotAvailable

let gpg_check file = function
  | GPGNotAvailable -> ()
  | GPGAvailable gpg_dir ->
    command_no_fail
      ~error:(fun () -> Printf.eprintf "Invalid signature for %s\n%!" file)
      "GNUPGHOME=%S gpg --verify %S > /dev/null 2>&1" gpg_dir (file^".asc")

(** {2 Download image} *)
(** use lxc download template facilities *)

let download_compat_level=2
let download_server = "images.linuxcontainers.org"

let download ?(quiet=true) fmt =
  Printf.ksprintf (fun src ->
      Printf.ksprintf (fun dst ->
          command "wget -T 30 %s https://%s/%s -O %S %s"
            (if quiet then  "-q" else "")
            download_server src dst
            (if quiet then  ">/dev/null 2>&1" else "")
        )
    ) fmt

let download_index ~dir ~gpg =
  let index = Filename.concat dir "index" in
  let url_index = "meta/1.0/index-user" in
  Printf.printf "Download the index: %!";
  if not (download
            "%s.%i" url_index download_compat_level
            "%s" index
          && download
            "%s.%i.asc" url_index download_compat_level
            "%s.asc" index) then
    if not (download "%s" url_index "%s" index
            && download
              "%s.asc" url_index
              "%s.asc" index) then begin
      Printf.eprintf "error.\n%!";
      exit 1;
    end;
  gpg_check index gpg;
  Printf.printf "done.\n%!";
  index

let semicomma = Str.regexp_string ";"

(** return download build and directory url *)
let find_image ~distr ~release ~arch index =
  let cin = open_in index in
  let rec aux () =
    match Str.split semicomma (input_line cin) with
    | [d;r;a;_;db;u] when d = distr && r = release && a = arch ->
      close_in cin; db,u
    | _ -> aux () in
  try
    aux ()
  with End_of_file -> close_in cin;
    Printf.eprintf "Can't find url in index corresponding to %s %s %s\n%!"
      distr release arch;
    exit 1

let download_rootfs_meta ~dir ~gpg (build_id,url) =
  let build_id_file = Filename.concat dir "build_id" in
  let rootfs_tar = Filename.concat dir "rootfs.tar.xz" in
  let meta_tar = Filename.concat dir "meta.tar.xz" in
  if not (Sys.file_exists build_id_file)
     || read_in_file "%s" build_id_file <> build_id then begin
    if Sys.file_exists build_id_file then Unix.unlink build_id_file;
    Printf.printf "Downloading rootfs.\n%!";
    if not (download ~quiet:false "%s/rootfs.tar.xz" url "%s/rootfs.tar.xz" dir
            && download "%s/rootfs.tar.xz.asc" url "%s/rootfs.tar.xz.asc" dir
            && download "%s/meta.tar.xz" url "%s/meta.tar.xz" dir
            && download "%s/meta.tar.xz.asc" url "%s/meta.tar.xz.asc" dir)
    then begin Printf.printf "error.\n%!"; exit 1 end;
    gpg_check rootfs_tar gpg;
    gpg_check meta_tar gpg;
    write_in_file "%s" build_id_file "%s" build_id
  end;
  rootfs_tar, meta_tar

(** {2 User namespace} *)
type userns_idmap =
  | KeepUser
  (** Put only the current user (uid,gid) as root in the userns *)
  | IdMap of int * int
  (** IdMap(id,rangeid): Map [1;rangeid] (uid,gid) in the userns to
      [id,id+rangeid] (current user is root in the userns) *)

let set_usermap idmap pid =
  let curr_uid = Unix.getuid () in
  let curr_gid = Unix.getgid () in
  (* write_in_file "/proc/%i/setgroups" pid "deny"; *)
  match idmap with
  | KeepUser ->
    write_in_file "/proc/%i/uid_map" pid "0 %i 1" curr_uid;
    write_in_file "/proc/%i/gid_map" pid "0 %i 1" curr_gid;
  | IdMap(id,rangeid) ->
    (* Printf.printf "pid: %i, mine: %i\n%!" pid (Unix.getpid ()); *)
    let error () = ignore (Unix.kill pid 9); exit 1 in
    command_no_fail ~error
      "newuidmap %i 0 %i 1 1 %i %i" pid curr_uid id rangeid;
    command_no_fail ~error
      "newgidmap %i 0 %i 1 1 %i %i" pid curr_gid id rangeid

let goto_child ~exec_in_parent =
  let fin,fout = Unix.pipe () in
  match Unix.fork () with
  | -1 -> Printf.eprintf "Fork failed\n%!"; exit 1
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
  | -1 -> Printf.eprintf "Fork failed\n%!"; exit 1
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

let exec_now_in_child f arg =
  match Unix.fork () with
  | -1 -> Printf.eprintf "Fork failed\n%!"; exit 1
  | 0 -> (** child *)
    f arg;
    exit 0
  | pid ->
    let _, status = Unix.waitpid [] pid in
    match status with
    | Unix.WEXITED 0 -> ()
    | Unix.WEXITED s -> exit s
    | Unix.WSIGNALED s -> Unix.kill (Unix.getpid ()) s; assert false
    | Unix.WSTOPPED _ -> assert false

let just_goto_child () =
  match Unix.fork () with
  | -1 -> Printf.eprintf "Fork failed\n%!"; exit 1
  | 0 -> (** child *) ()
  | pid ->
    let _, status = Unix.waitpid [] pid in
    match status with
    | Unix.WEXITED s -> exit s
    | Unix.WSIGNALED s -> Unix.kill (Unix.getpid ()) s; assert false
    | Unix.WSTOPPED _ -> assert false


let go_in_userns idmap =
  (** the usermap can be set only completely outside the namespace, so we
      keep a child for doing that when we have a pid completely inside the
      namespace *)
  let call_set_usermap = exec_in_child (set_usermap idmap) in
  unshare [ CLONE_NEWNS;
            CLONE_NEWIPC;
            CLONE_NEWPID;
            CLONE_NEWUTS;
            CLONE_NEWUSER;
          ];
  (** only the child will be in the new pid namespace, the parent is in an
      intermediary state not interesting *)
  goto_child ~exec_in_parent:call_set_usermap
  (* Printf.printf "User: %i (%i)\n%!" (Unix.getuid ()) (Unix.geteuid ()); *)
  (* Printf.printf "Pid: %i\n%!" (Unix.getpid ()); *)
  (* Printf.printf "User: %i (%i)\n%!" (Unix.getuid ()) (Unix.geteuid ()); *)

let create_rootfs ~distr ~release ~arch testdir =
  let rootfsdir = Filename.concat testdir "rootfs" in
  if not (Sys.file_exists rootfsdir) then begin
    let gpg = gpg_setup ~dir:testdir in
    let index = download_index ~dir:testdir ~gpg in
    let url =
      find_image ~distr ~release ~arch index in
    let rootfs, meta = download_rootfs_meta ~dir:testdir ~gpg url in
    let metadir = Filename.concat testdir "meta" in
    command_no_fail "rm -rf %S" metadir;
    mkdir metadir;
    command_no_fail "tar Jxf %S -C %S" meta metadir;
  mkdir ~perm:0o750 rootfsdir;
    let error () =
    Printf.printf "error\n%!";
    command_no_fail "rm -rf %S" rootfsdir in
    let exclude = Filename.concat metadir "excludes-user" in
    Printf.printf "Uncompressing rootfs:%!";
    if Sys.file_exists exclude
    then command_no_fail ~error
        "tar Jxf %S -C %S --exclude-from %S \
         --numeric-owner --preserve-permissions --preserve-order --same-owner"
        rootfs rootfsdir exclude
    else command_no_fail ~error "tar Jxf %S -C %S" rootfs rootfsdir;
    Printf.printf "done.\n%!";
  end;
  rootfsdir

let idmap, (cmd,arg), testdir, setuid, setgid, arch, distr, release =
  let open Arg in
  let testdir = ref "userns_test" in
  let idmap_id = ref (-1) in
  let idmap_rangeid = ref (-1) in
  let command = ref [] in
  let setuid = ref 0 in
  let setgid = ref 0 in
  let arch = ref "amd64" in
  let distr = ref "debian" in
  let release = ref "jessie" in
  parse (align [
      "--dir",
      Set_string testdir,
      "dir Directory to use for the test \
       (dir/rootfs is used for root directory)";
      "--idmap",
      Tuple [Set_int idmap_id;Set_int idmap_rangeid],
      "id_range maps additionally uid/gid [1;range] to [id;id+range]\n\t\
       you need a configured /etc/subuid (man subuid)";
      "--uid",
      Set_int setuid,
      "uid Execute the command as this uid inside the user namespace";
      "--gid",
      Set_int setgid,
      "gid Execute the command as this gid inside the user namespace";
      "--arch",
      Set_string arch,
      "arch Specify the architecture of the image \
       (eg. amd64, i386, armel,armhf)";
      "--distr",
      Tuple [Set_string distr; Set_string release],
      "distr_release Specify the distribution and release of the image \
       (eg. centos 6, debian jessie, ubuntu precise, gentoo current)";
      "--",
      Rest (fun s -> command := s::!command),
      "Instead of running /bin/bash in the usernamespace, run the given command"
    ])
    (fun _ -> raise (Bad "no anonymous option"))
    "Test for user-namespace: you need linux at least 3.18. \
     In the user-namespace the\n\
     current user is root. Use LXC download template facilities for getting\n\
     the root filesystem.";
  let idmap =
    match !idmap_id, !idmap_rangeid with
    | (-1), _ | _, (-1) -> KeepUser
    | id, range -> IdMap(id,range)
  in
  let command =
    match List.rev !command with
    | [] -> "/bin/bash",[|"bash"|]
    | (cmd::_) as l -> cmd, Array.of_list l in
  idmap, command, !testdir, !setuid, !setgid, !arch, !distr, !release

let () =
  if Unix.getuid () = 0 then begin
    Printf.eprintf "This program shouldn't be run as root!\n%!";
    exit 1
  end;
  Unix.handle_unix_error begin fun () ->
    test_userns_availability ();
    mkdir ~perm:0o750 testdir;
    go_in_userns idmap;
    let rootfsdir = create_rootfs ~arch ~distr ~release testdir in
    command_no_fail "cp /etc/resolv.conf %S"
      (Filename.concat rootfsdir "etc/resolv.conf");
    (** make the mount private and mount basic directories *)
    mount_base rootfsdir;
    (** chroot in the directory *)
    do_chroot rootfsdir;
    (** group must be changed before uid... *)
    setresgid setgid setgid setgid;
    setresuid setuid setuid setuid;
    let path =
      (if setuid = 0 then "/usr/local/sbin:/usr/sbin:/sbin:" else "")^
      "/usr/local/bin:/usr/bin:/bin" in
    Unix.putenv "PATH" path;
    Unix.execv cmd arg
  end ()
