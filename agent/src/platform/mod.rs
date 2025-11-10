// Platform-specific implementations

#[cfg(target_os = "windows")]
pub mod windows;

#[cfg(target_os = "linux")]
pub mod linux;

#[cfg(target_os = "macos")]
pub mod macos;

// Common platform traits
pub trait PlatformInfo {
    fn os_name(&self) -> String;
    fn os_version(&self) -> String;
    fn hostname(&self) -> String;
}
