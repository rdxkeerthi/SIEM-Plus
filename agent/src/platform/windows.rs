// Windows-specific implementations
use super::PlatformInfo;

pub struct WindowsPlatform;

impl PlatformInfo for WindowsPlatform {
    fn os_name(&self) -> String {
        "Windows".to_string()
    }

    fn os_version(&self) -> String {
        // TODO: Get actual Windows version
        "10".to_string()
    }

    fn hostname(&self) -> String {
        // TODO: Get actual hostname
        "localhost".to_string()
    }
}
