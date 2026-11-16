// ZigXp: Bringing back zig to windows xp!
// -----------------------------------------------------------
// This file contains phantom declarations for missing functions in winxp's ntdll lib that zig uses.
// Some of them are correctly emulated while others are hard/impossible to emulate with old ntdll api but they
// are declared anyway to prevent linking errors (Thats's not safe so be carefull).
// -----------------------------------------------------------
// Project repo: https://github.com/Youssef-Afella/zigxp

const std = @import("std");
const windows = std.os.windows;

// Replaces windows.RUNTIME_FUNCTION since it has no direct x86 equivalent
const RUNTIME_FUNCTION = anyopaque;

// Replaces windows.KNONVOLATILE_CONTEXT_POINTERS since it has no direct x86 equivalent
const KNONVOLATILE_CONTEXT_POINTERS = anyopaque;

// ---
// Simple
// ---
extern "kernel32" fn GetSystemTimeAsFileTime(out: *windows.LARGE_INTEGER) callconv(.winapi) void;
pub fn rtlGetSystemTimePrecise() callconv(.winapi) windows.LARGE_INTEGER {
    var t: windows.LARGE_INTEGER = 0;
    GetSystemTimeAsFileTime(&t);
    return t;
}

extern "kernel32" fn QueryPerformanceCounter(out: *windows.LARGE_INTEGER) callconv(.winapi) windows.BOOL;
pub fn rtlQueryPerformanceCounter(PerformanceCounter: *windows.LARGE_INTEGER) callconv(.winapi) windows.BOOL {
    return QueryPerformanceCounter(PerformanceCounter);
}

extern "kernel32" fn QueryPerformanceFrequency(out: *windows.LARGE_INTEGER) callconv(.winapi) windows.BOOL;
pub fn rtlQueryPerformanceFrequency(PerformanceFrequency: *windows.LARGE_INTEGER) callconv(.winapi) windows.BOOL {
    return QueryPerformanceFrequency(PerformanceFrequency);
}

extern "kernel32" fn ExitProcess(code: u32) callconv(.winapi) noreturn;
pub fn rtlExitUserProcess(ExitStatus: u32) callconv(.winapi) noreturn {
    ExitProcess(ExitStatus);
}

// ---
// Downgrade
// ---
pub fn ntCancelIoFileEx(FileHandle: windows.HANDLE, IoRequestToCancel: *const windows.IO_STATUS_BLOCK, IoStatusBlock: *windows.IO_STATUS_BLOCK) callconv(.winapi) windows.NTSTATUS {
    _ = IoRequestToCancel;
    return windows.ntdll.NtCancelIoFile(FileHandle, IoStatusBlock);
}

pub fn ntOpenKeyEx(KeyHandle: *windows.HANDLE, DesiredAccess: windows.ACCESS_MASK, ObjectAttributes: *const windows.OBJECT.ATTRIBUTES, OpenOptions: windows.REG.OpenOptions) callconv(.winapi) windows.NTSTATUS {
    _ = OpenOptions;
    // in zig source code (zig 0.17 so far, might change in the future) the OpenOptions was always set to default value (zeroed) so passing them is not necessary
    // using the old NtOpenKey is equivalent to NtOpenKeyEx with zeroed options : https://ntdoc.m417z.com/ntopenkey
    return windows.ntdll.NtOpenKey(KeyHandle, DesiredAccess, ObjectAttributes);
}

// ---
// Hard-Coded
// ---
pub fn ntWaitForAlertByThreadId(Address: ?*const anyopaque, Timeout: ?*const windows.LARGE_INTEGER) callconv(.winapi) windows.NTSTATUS {
    _ = Address;
    _ = Timeout;
    return .TIMEOUT;
}

// ---
// WIP
// ---
pub fn rtlLookupFunctionEntry(
    ControlPc: usize,
    ImageBase: *usize,
    HistoryTable: *windows.UNWIND_HISTORY_TABLE,
) callconv(.winapi) ?*RUNTIME_FUNCTION {
    _ = ControlPc;
    _ = ImageBase;
    _ = HistoryTable;
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
    _ = HandlerType;
    _ = ImageBase;
    _ = ControlPc;
    _ = FunctionEntry;
    _ = ContextRecord;
    _ = HandlerData;
    _ = EstablisherFrame;
    _ = ContextPointers;
    return undefined;
}

pub fn ldrRegisterDllNotification(
    Flags: windows.LDR.DLL_NOTIFICATION.REGISTER,
    NotificationFunction: *const windows.LDR.DLL_NOTIFICATION.FUNCTION,
    Context: ?windows.PVOID,
    Cookie: *windows.LDR.DLL_NOTIFICATION.COOKIE,
) callconv(.winapi) windows.NTSTATUS {
    _ = Flags;
    _ = NotificationFunction;
    _ = Context;
    _ = Cookie;
    return @fromBackingInt(0);
}

pub fn ldrUnregisterDllNotification(
    Cookie: windows.LDR.DLL_NOTIFICATION.COOKIE,
) callconv(.winapi) windows.NTSTATUS {
    _ = Cookie;
    return @fromBackingInt(0);
}

pub fn ntCancelSynchronousIoFile(
    ThreadHandle: windows.HANDLE,
    IoRequestToCancel: ?*windows.IO_STATUS_BLOCK,
    IoStatusBlock: *windows.IO_STATUS_BLOCK,
) callconv(.winapi) windows.NTSTATUS {
    _ = ThreadHandle;
    _ = IoRequestToCancel;
    _ = IoStatusBlock;
    return @fromBackingInt(0);
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
    return @fromBackingInt(0);
}

pub fn ntSetInformationVirtualMemory(
    ProcessHandle: windows.HANDLE,
    VmInformationClass: windows.VIRTUAL_MEMORY.INFORMATION_CLASS,
    NumberOfExtries: windows.SIZE_T,
    VirtualAddresses: [*]const windows.MEMORY_RANGE_ENTRY,
    VmInformation: *anyopaque,
    VmInformationLength: windows.DWORD,
) callconv(.winapi) windows.NTSTATUS {
    _ = ProcessHandle;
    _ = VmInformationClass;
    _ = NumberOfExtries;
    _ = VirtualAddresses;
    _ = VmInformation;
    _ = VmInformationLength;
    return @fromBackingInt(0);
}

pub fn ntAlertThreadByThreadId(
    ThreadId: windows.DWORD,
) callconv(.winapi) windows.NTSTATUS {
    _ = ThreadId;
    return @fromBackingInt(0);
}

pub fn ntAlertMultipleThreadByThreadId(
    ThreadIds: [*]const windows.ULONG_PTR,
    ThreadCount: windows.ULONG,
    Unknown1: ?*const anyopaque,
    Unknown2: ?*const anyopaque,
) callconv(.winapi) windows.NTSTATUS {
    _ = ThreadIds;
    _ = ThreadCount;
    _ = Unknown1;
    _ = Unknown2;
    return @fromBackingInt(0);
}

pub fn rtlReportSilentProcessExit(
    ProcessHandle: windows.HANDLE,
    ExitStatus: windows.NTSTATUS,
) callconv(.winapi) windows.NTSTATUS {
    _ = ProcessHandle;
    _ = ExitStatus;
    return @fromBackingInt(0);
}

pub fn rtlWaitOnAddress(
    Address: ?*const anyopaque,
    CompareAddress: ?*const anyopaque,
    AddressSize: windows.SIZE_T,
    Timeout: ?*const windows.LARGE_INTEGER,
) callconv(.winapi) windows.NTSTATUS {
    _ = Address;
    _ = CompareAddress;
    _ = AddressSize;
    _ = Timeout;
    return @fromBackingInt(0);
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
    _ = TargetKey;
    _ = SourceFile;
    _ = Flags;
    _ = TrustClassKey;
    _ = Event;
    _ = DesiredAccess;
    _ = RootHandle;
    _ = Reserved;
    return @fromBackingInt(0);
}

pub fn ntCreateThreadEx(
    ThreadHandle: *windows.HANDLE,
    DesiredAccess: windows.ACCESS_MASK,
    ObjectAttributes: *const windows.OBJECT.ATTRIBUTES,
    ProcessHandle: windows.HANDLE,
    StartRoutine: *const windows.USER_THREAD_START_ROUTINE,
    Argument: ?windows.PVOID,
    CreateFlags: windows.THREAD.CREATE_FLAGS,
    ZeroBits: windows.SIZE_T,
    StackCommit: windows.THREAD.StackSize,
    StackReserve: windows.THREAD.StackSize,
    AttributeList: ?*windows.PS.ATTRIBUTE.LIST,
) callconv(.winapi) windows.NTSTATUS {
    _ = ThreadHandle;
    _ = DesiredAccess;
    _ = ObjectAttributes;
    _ = ProcessHandle;
    _ = StartRoutine;
    _ = Argument;
    _ = CreateFlags;
    _ = ZeroBits;
    _ = StackCommit;
    _ = StackReserve;
    _ = AttributeList;
    return @fromBackingInt(0);
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
