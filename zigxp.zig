// ZigXp: Bringing back zig to windows xp!
// -----------------------------------------------------------
// This file contains phantom declarations for missing functions in winxp's ntdll lib that zig uses.
// Some of them are correctly emulated while others are hard/impossible to emulate with old ntdll api but they
// are declared anyway to prevent linking errors (Thats's not safe so be carefull).
// -----------------------------------------------------------
// Project repo: https://github.com/Youssef-Afella/zigxp

// ---
// Config
// ---
const SAFETY: SAFETY_LEVEL = .MEDIUM;
// STRICT: any function that cannot be reproduced 100% we panic when it gets called
// MEDIUM: if possible, approxiamtes the behaviour with a similar function; if not, returns an error NSTATUS but doesn't panic
// UNSAFE: approxiamtes the behaviour with a similar function if possible or blindly returns a success NSTATUS

const LOG_CALLS: bool = true;
const LOG_VERBOSE_CALLS: bool = false;
// Prints the calls to the console
// VERBOSE are just bunch of functions I choose that usually get called every frame (like time) and polute our logger

// ---
// Simple
// ---
const std = @import("std");
const windows = std.os.windows;

extern "kernel32" fn GetSystemTimeAsFileTime(out: *windows.LARGE_INTEGER) callconv(.winapi) void;
pub fn rtlGetSystemTimePrecise() callconv(.winapi) windows.LARGE_INTEGER {
    if (LOG_VERBOSE_CALLS) LOG(@src().fn_name);

    var t: windows.LARGE_INTEGER = 0;
    GetSystemTimeAsFileTime(&t);
    return t;
}

extern "kernel32" fn QueryPerformanceCounter(out: *windows.LARGE_INTEGER) callconv(.winapi) windows.BOOL;
pub fn rtlQueryPerformanceCounter(PerformanceCounter: *windows.LARGE_INTEGER) callconv(.winapi) windows.BOOL {
    if (LOG_VERBOSE_CALLS) LOG(@src().fn_name);

    return QueryPerformanceCounter(PerformanceCounter);
}

extern "kernel32" fn QueryPerformanceFrequency(out: *windows.LARGE_INTEGER) callconv(.winapi) windows.BOOL;
pub fn rtlQueryPerformanceFrequency(PerformanceFrequency: *windows.LARGE_INTEGER) callconv(.winapi) windows.BOOL {
    if (LOG_VERBOSE_CALLS) LOG(@src().fn_name);

    return QueryPerformanceFrequency(PerformanceFrequency);
}

extern "kernel32" fn ExitProcess(code: u32) callconv(.winapi) noreturn;
pub fn rtlExitUserProcess(ExitStatus: u32) callconv(.winapi) noreturn {
    if (LOG_CALLS) LOG(@src().fn_name);

    ExitProcess(ExitStatus);
}

// ---
// Downgrade
// ---
pub fn ntOpenKeyEx(KeyHandle: *windows.HANDLE, DesiredAccess: windows.ACCESS_MASK, ObjectAttributes: *const windows.OBJECT.ATTRIBUTES, OpenOptions: windows.REG.OpenOptions) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    // using the old NtOpenKey is equivalent to NtOpenKeyEx with zeroed options : https://ntdoc.m417z.com/ntopenkey
    // so we let it slide event in strict
    const default_options = std.mem.zeroes(windows.REG.OpenOptions);
    if (OpenOptions != default_options) {
        if (SAFETY == .STRICT) {
            PANIC(@src().fn_name);
        } else if (SAFETY == .MEDIUM) {
            return .NOT_SUPPORTED;
        }
    }
    return windows.ntdll.NtOpenKey(KeyHandle, DesiredAccess, ObjectAttributes);
}

extern "ntdll" fn RtlCreateUserThread(ProcessHandle: windows.HANDLE, ThreadSecurityDescriptor: ?*anyopaque, CreateSuspended: windows.BOOLEAN, ZeroBits: windows.ULONG, MaximumStackSize: windows.SIZE_T, CommittedStackSize: windows.SIZE_T, StartAddress: *const windows.USER_THREAD_START_ROUTINE, Parameter: ?windows.PVOID, ThreadHandle: ?*windows.HANDLE, ClientId: ?*windows.CLIENT_ID) callconv(.winapi) windows.NTSTATUS;
pub fn ntCreateThreadEx(ThreadHandle: *windows.HANDLE, DesiredAccess: windows.ACCESS_MASK, ObjectAttributes: *const windows.OBJECT.ATTRIBUTES, ProcessHandle: windows.HANDLE, StartRoutine: *const windows.USER_THREAD_START_ROUTINE, Argument: ?windows.PVOID, CreateFlags: windows.THREAD.CREATE_FLAGS, ZeroBits: windows.SIZE_T, StackCommit: windows.THREAD.StackSize, StackReserve: windows.THREAD.StackSize, AttributeList: ?*windows.PS.ATTRIBUTE.LIST) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = DesiredAccess;
    _ = ObjectAttributes;
    _ = AttributeList;

    if (SAFETY == .STRICT) {
        // This function doesn't have the full behaviour as the other one so we panic at strict
        PANIC(@src().fn_name);
    }

    // https://ntdoc.m417z.com/thread_create_flags_create_suspended
    const THREAD_CREATE_FLAGS_CREATE_SUSPENDED = 0x00000001;
    const create_suspended: windows.BOOLEAN = if ((@as(u32, @bitCast(CreateFlags)) & THREAD_CREATE_FLAGS_CREATE_SUSPENDED) != 0) windows.BOOLEAN.TRUE else windows.BOOLEAN.FALSE;

    const zero_bits: windows.ULONG = @truncate(ZeroBits);
    var client_id: windows.CLIENT_ID = undefined;

    return RtlCreateUserThread(ProcessHandle, null, create_suspended, zero_bits, @backingInt(StackReserve), @backingInt(StackCommit), StartRoutine, Argument, ThreadHandle, &client_id);
}

pub fn ntCancelIoFileEx(FileHandle: windows.HANDLE, IoRequestToCancel: *const windows.IO_STATUS_BLOCK, IoStatusBlock: *windows.IO_STATUS_BLOCK) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    if (SAFETY == .STRICT) {
        // This function doesn't have the full behaviour as the other one so we panic at strict
        PANIC(@src().fn_name);
    }

    if (@as(usize, @intFromPtr(IoRequestToCancel)) != 0 and SAFETY == .MEDIUM) {
        return .NOT_SUPPORTED;
    }

    // This version cancel all IO operations issued by the current thread only
    return windows.ntdll.NtCancelIoFile(FileHandle, IoStatusBlock);
}

// ---
// Hard-Coded
// ---
pub fn ntWaitForAlertByThreadId(Address: ?*const anyopaque, Timeout: ?*const windows.LARGE_INTEGER) callconv(.winapi) windows.NTSTATUS {
    if (LOG_VERBOSE_CALLS) LOG(@src().fn_name);

    _ = Address;
    _ = Timeout;

    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }
    return .TIMEOUT;
}

// ---
// WIP
// ---

// Replaces windows.RUNTIME_FUNCTION since it has no direct x86 equivalent
const RUNTIME_FUNCTION = anyopaque;
// Replaces windows.KNONVOLATILE_CONTEXT_POINTERS since it has no direct x86 equivalent
const KNONVOLATILE_CONTEXT_POINTERS = anyopaque;

pub fn rtlLookupFunctionEntry(
    ControlPc: usize,
    ImageBase: *usize,
    HistoryTable: *windows.UNWIND_HISTORY_TABLE,
) callconv(.winapi) ?*RUNTIME_FUNCTION {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = ControlPc;
    _ = ImageBase;
    _ = HistoryTable;

    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return null;
}

pub fn rtlVirtualUnwind(
    HandlerType: windows.DWORD,
    ImageBase: usize,
    ControlPc: usize,
    FunctionEntry: *RUNTIME_FUNCTION,
    ContextRecord: *windows.CONTEXT,
    HandlerData: *?windows.PVOID,
    EstablisherFrame: *usize,
    ContextPointers: ?*KNONVOLATILE_CONTEXT_POINTERS,
) callconv(.winapi) *windows.EXCEPTION_ROUTINE {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = HandlerType;
    _ = ImageBase;
    _ = ControlPc;
    _ = FunctionEntry;
    _ = ContextRecord;
    _ = HandlerData;
    _ = EstablisherFrame;
    _ = ContextPointers;

    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return undefined;
}

pub fn ldrRegisterDllNotification(
    Flags: windows.LDR.DLL_NOTIFICATION.REGISTER,
    NotificationFunction: *const windows.LDR.DLL_NOTIFICATION.FUNCTION,
    Context: ?windows.PVOID,
    Cookie: *windows.LDR.DLL_NOTIFICATION.COOKIE,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = Flags;
    _ = NotificationFunction;
    _ = Context;
    _ = Cookie;

    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

pub fn ldrUnregisterDllNotification(
    Cookie: windows.LDR.DLL_NOTIFICATION.COOKIE,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = Cookie;
    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

pub fn ntCancelSynchronousIoFile(
    ThreadHandle: windows.HANDLE,
    IoRequestToCancel: ?*windows.IO_STATUS_BLOCK,
    IoStatusBlock: *windows.IO_STATUS_BLOCK,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = ThreadHandle;
    _ = IoRequestToCancel;
    _ = IoStatusBlock;

    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

pub fn ntNotifyChangeDirectoryFileEx(
    FileHandle: windows.HANDLE,
    Event: ?windows.HANDLE,
    ApcRoutine: ?*align(2) const windows.IO_APC_ROUTINE,
    ApcContext: ?*anyopaque,
    IoStatusBlock: *windows.IO_STATUS_BLOCK,
    Buffer: *anyopaque,
    Length: windows.ULONG,
    CompletionFilter: windows.FILE.NOTIFY.CHANGE,
    WatchTree: windows.BOOLEAN,
    DirectoryNotifyInformationClass: windows.DIRECTORY.NOTIFY_INFORMATION_CLASS,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = FileHandle;
    _ = Event;
    _ = ApcRoutine;
    _ = ApcContext;
    _ = IoStatusBlock;
    _ = Buffer;
    _ = Length;
    _ = CompletionFilter;
    _ = WatchTree;
    _ = DirectoryNotifyInformationClass;

    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

pub fn ntSetInformationVirtualMemory(
    ProcessHandle: windows.HANDLE,
    VmInformationClass: windows.VIRTUAL_MEMORY.INFORMATION_CLASS,
    NumberOfExtries: windows.SIZE_T,
    VirtualAddresses: [*]const windows.MEMORY_RANGE_ENTRY,
    VmInformation: *anyopaque,
    VmInformationLength: windows.DWORD,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = ProcessHandle;
    _ = VmInformationClass;
    _ = NumberOfExtries;
    _ = VirtualAddresses;
    _ = VmInformation;
    _ = VmInformationLength;
    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

pub fn ntAlertThreadByThreadId(
    ThreadId: windows.DWORD,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = ThreadId;
    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

pub fn ntAlertMultipleThreadByThreadId(
    ThreadIds: [*]const windows.ULONG_PTR,
    ThreadCount: windows.ULONG,
    Unknown1: ?*const anyopaque,
    Unknown2: ?*const anyopaque,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = ThreadIds;
    _ = ThreadCount;
    _ = Unknown1;
    _ = Unknown2;
    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

pub fn rtlReportSilentProcessExit(
    ProcessHandle: windows.HANDLE,
    ExitStatus: windows.NTSTATUS,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = ProcessHandle;
    _ = ExitStatus;
    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

pub fn rtlWaitOnAddress(
    Address: ?*const anyopaque,
    CompareAddress: ?*const anyopaque,
    AddressSize: windows.SIZE_T,
    Timeout: ?*const windows.LARGE_INTEGER,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = Address;
    _ = CompareAddress;
    _ = AddressSize;
    _ = Timeout;

    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

pub fn ntLoadKeyEx(
    TargetKey: *const windows.OBJECT.ATTRIBUTES,
    SourceFile: *const windows.OBJECT.ATTRIBUTES,
    Flags: windows.REG.LoadOptions,
    TrustClassKey: ?windows.HANDLE,
    Event: ?windows.HANDLE,
    DesiredAccess: windows.ACCESS_MASK,
    RootHandle: ?*windows.HANDLE,
    Reserved: ?*anyopaque,
) callconv(.winapi) windows.NTSTATUS {
    if (LOG_CALLS) LOG(@src().fn_name);

    _ = TargetKey;
    _ = SourceFile;
    _ = Flags;
    _ = TrustClassKey;
    _ = Event;
    _ = DesiredAccess;
    _ = RootHandle;
    _ = Reserved;

    if (SAFETY == .STRICT) {
        PANIC(@src().fn_name);
    }

    return if (SAFETY == .MEDIUM) .NOT_SUPPORTED else .SUCCESS;
}

comptime {
    @export(&rtlGetSystemTimePrecise, .{ .name = "RtlGetSystemTimePrecise" });
    @export(&rtlQueryPerformanceCounter, .{ .name = "RtlQueryPerformanceCounter" });
    @export(&rtlQueryPerformanceFrequency, .{ .name = "RtlQueryPerformanceFrequency" });
    @export(&rtlExitUserProcess, .{ .name = "RtlExitUserProcess" });

    @export(&ntCancelIoFileEx, .{ .name = "NtCancelIoFileEx" });
    @export(&ntWaitForAlertByThreadId, .{ .name = "NtWaitForAlertByThreadId" });
    @export(&ntOpenKeyEx, .{ .name = "NtOpenKeyEx" });

    @export(&ntLoadKeyEx, .{ .name = "NtLoadKeyEx" });
    @export(&rtlLookupFunctionEntry, .{ .name = "RtlLookupFunctionEntry" });
    @export(&rtlVirtualUnwind, .{ .name = "RtlVirtualUnwind" });
    @export(&ldrRegisterDllNotification, .{ .name = "LdrRegisterDllNotification" });
    @export(&ldrUnregisterDllNotification, .{ .name = "LdrUnregisterDllNotification" });
    @export(&ntCancelSynchronousIoFile, .{ .name = "NtCancelSynchronousIoFile" });
    @export(&ntNotifyChangeDirectoryFileEx, .{ .name = "NtNotifyChangeDirectoryFileEx" });
    @export(&ntSetInformationVirtualMemory, .{ .name = "NtSetInformationVirtualMemory" });
    @export(&ntAlertThreadByThreadId, .{ .name = "NtAlertThreadByThreadId" });
    @export(&ntAlertMultipleThreadByThreadId, .{ .name = "NtAlertMultipleThreadByThreadId" });
    @export(&rtlReportSilentProcessExit, .{ .name = "RtlReportSilentProcessExit" });
    @export(&rtlWaitOnAddress, .{ .name = "RtlWaitOnAddress" });
    @export(&ntCreateThreadEx, .{ .name = "NtCreateThreadEx" });
}

// ---
// Utility
// ---

const SAFETY_LEVEL = enum(u8) {
    UNSAFE,
    MEDIUM,
    STRICT,
};

extern "kernel32" fn GetStdHandle(nStdHandle: windows.DWORD) callconv(.winapi) windows.HANDLE;
extern "kernel32" fn WriteFile(hFile: windows.HANDLE, lpBuffer: [*]const u8, nNumberOfBytesToWrite: windows.DWORD, lpNumberOfBytesWritten: ?*windows.DWORD, lpOverlapped: ?*anyopaque) callconv(.winapi) windows.BOOL;

fn LOG(comptime s: []const u8) void {
    const STD_OUTPUT_HANDLE: windows.DWORD = 0xFFFFFFF5;
    const handle = GetStdHandle(STD_OUTPUT_HANDLE);

    var written: windows.DWORD = 0;
    const msg = std.fmt.comptimePrint("[ZIGXP]: {s}\n", .{s});
    _ = WriteFile(handle, msg.ptr, @intCast(msg.len), &written, null);
}

fn PANIC(comptime s: []const u8) void {
    @panic(std.fmt.comptimePrint("[ZIGXP] Unsupported Function Call: {s}\n", .{s}));
}
