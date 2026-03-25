#define EXTUNIX_WANT_LANDLOCK
#include "config.h"

#if defined(EXTUNIX_HAVE_LANDLOCK)

#define TABLE_LEN(t) (sizeof(t) / sizeof(t[0]))

/*
 * Custom flag list to __u64 conversion.
 * caml_convert_flag_list returns int, but landlock uses __u64 bitmasks.
 */
static __u64 convert_flag_list_u64(value list, const __u64 *table, size_t table_len)
{
    __u64 res = 0;
    while (list != Val_int(0)) {
        int flag = Int_val(Field(list, 0));
        if (flag >= 0 && (size_t)flag < table_len)
            res |= table[flag];
        list = Field(list, 1);
    }
    return res;
}

/* Order must match OCaml access_fs type */
static const __u64 access_fs_table[] = {
    LANDLOCK_ACCESS_FS_EXECUTE,
    LANDLOCK_ACCESS_FS_WRITE_FILE,
    LANDLOCK_ACCESS_FS_READ_FILE,
    LANDLOCK_ACCESS_FS_READ_DIR,
    LANDLOCK_ACCESS_FS_REMOVE_DIR,
    LANDLOCK_ACCESS_FS_REMOVE_FILE,
    LANDLOCK_ACCESS_FS_MAKE_CHAR,
    LANDLOCK_ACCESS_FS_MAKE_DIR,
    LANDLOCK_ACCESS_FS_MAKE_REG,
    LANDLOCK_ACCESS_FS_MAKE_SOCK,
    LANDLOCK_ACCESS_FS_MAKE_FIFO,
    LANDLOCK_ACCESS_FS_MAKE_BLOCK,
    LANDLOCK_ACCESS_FS_MAKE_SYM,
    LANDLOCK_ACCESS_FS_REFER,
    LANDLOCK_ACCESS_FS_TRUNCATE,
    LANDLOCK_ACCESS_FS_IOCTL_DEV,
};

#if LANDLOCK_ACCESS_NET_BIND_TCP
/* Order must match OCaml access_net type */
static const __u64 access_net_table[] = {
    LANDLOCK_ACCESS_NET_BIND_TCP,
    LANDLOCK_ACCESS_NET_CONNECT_TCP,
};
#endif

#if LANDLOCK_SCOPE_ABSTRACT_UNIX_SOCKET
/* Order must match OCaml scope type */
static const __u64 scope_table[] = {
    LANDLOCK_SCOPE_ABSTRACT_UNIX_SOCKET,
    LANDLOCK_SCOPE_SIGNAL,
};
#endif

CAMLprim value caml_extunix_landlock_abi_version(value v_unit)
{
    long ret;
    UNUSED(v_unit);
    ret = syscall(__NR_landlock_create_ruleset, NULL, 0,
                  LANDLOCK_CREATE_RULESET_VERSION);
    if (ret < 0) {
        if (errno == ENOSYS || errno == EOPNOTSUPP)
            return Val_int(0);
        caml_uerror("landlock_create_ruleset(VERSION)", Nothing);
    }
    return Val_int(ret);
}

CAMLprim value caml_extunix_landlock_create_ruleset(
    value v_access_fs, value v_access_net, value v_scoped)
{
    CAMLparam3(v_access_fs, v_access_net, v_scoped);
    struct landlock_ruleset_attr attr;
    long ret;

    memset(&attr, 0, sizeof(attr));
    attr.handled_access_fs = convert_flag_list_u64(
        v_access_fs, access_fs_table, TABLE_LEN(access_fs_table));
#if LANDLOCK_ACCESS_NET_BIND_TCP
    attr.handled_access_net = convert_flag_list_u64(
        v_access_net, access_net_table, TABLE_LEN(access_net_table));
#else
    (void)v_access_net;
#endif
#if LANDLOCK_SCOPE_ABSTRACT_UNIX_SOCKET
    attr.scoped = convert_flag_list_u64(
        v_scoped, scope_table, TABLE_LEN(scope_table));
#else
    (void)v_scoped;
#endif

    ret = syscall(__NR_landlock_create_ruleset, &attr, sizeof(attr), 0);
    if (ret < 0)
        caml_uerror("landlock_create_ruleset", Nothing);

    CAMLreturn(Val_int(ret));
}

CAMLprim value caml_extunix_landlock_add_rule_path_beneath(
    value v_ruleset_fd, value v_allowed_access, value v_parent_fd)
{
    CAMLparam3(v_ruleset_fd, v_allowed_access, v_parent_fd);
    struct landlock_path_beneath_attr attr;
    long ret;

    memset(&attr, 0, sizeof(attr));
    attr.allowed_access = convert_flag_list_u64(
        v_allowed_access, access_fs_table, TABLE_LEN(access_fs_table));
    attr.parent_fd = Int_val(v_parent_fd);

    ret = syscall(__NR_landlock_add_rule, Int_val(v_ruleset_fd),
                  LANDLOCK_RULE_PATH_BENEATH, &attr, 0);
    if (ret < 0)
        caml_uerror("landlock_add_rule(PATH_BENEATH)", Nothing);

    CAMLreturn(Val_unit);
}

#if LANDLOCK_ACCESS_NET_BIND_TCP
CAMLprim value caml_extunix_landlock_add_rule_net_port(
    value v_ruleset_fd, value v_allowed_access, value v_port)
{
    CAMLparam3(v_ruleset_fd, v_allowed_access, v_port);
    struct landlock_net_port_attr attr;
    long ret;

    memset(&attr, 0, sizeof(attr));
    attr.allowed_access = convert_flag_list_u64(
        v_allowed_access, access_net_table, TABLE_LEN(access_net_table));
    attr.port = Long_val(v_port);

    ret = syscall(__NR_landlock_add_rule, Int_val(v_ruleset_fd),
                  LANDLOCK_RULE_NET_PORT, &attr, 0);
    if (ret < 0)
        caml_uerror("landlock_add_rule(NET_PORT)", Nothing);

    CAMLreturn(Val_unit);
}
#else
CAMLprim value caml_extunix_landlock_add_rule_net_port(
    value v_ruleset_fd, value v_allowed_access, value v_port)
{
    UNUSED(v_ruleset_fd);
    UNUSED(v_allowed_access);
    UNUSED(v_port);
    errno = ENOSYS;
    caml_uerror("landlock_add_rule(NET_PORT)", Nothing);
    return Val_unit; /* unreachable */
}
#endif

CAMLprim value caml_extunix_landlock_restrict_self(value v_ruleset_fd)
{
    CAMLparam1(v_ruleset_fd);
    long ret;

    ret = syscall(__NR_landlock_restrict_self, Int_val(v_ruleset_fd), 0);
    if (ret < 0)
        caml_uerror("landlock_restrict_self", Nothing);

    CAMLreturn(Val_unit);
}

#endif /* EXTUNIX_HAVE_LANDLOCK */
