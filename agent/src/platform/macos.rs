// macOS-specific implementations
use super::PlatformInfo;

pub struct MacOSPlatform;

impl PlatformInfo for MacOSPlatform {
    fn os_name(&self) -> String {
        "macOS".to_string()
    }

    fn os_version(&self) -> String {
        // TODO: Get actual macOS version
        "Unknown".to_string()
    }

    fn hostname(&self) -> String {
        // TODO: Get actual hostname
        "localhost".to_string()
    }
}
