// Linux-specific implementations
use super::PlatformInfo;

pub struct LinuxPlatform;

impl PlatformInfo for LinuxPlatform {
    fn os_name(&self) -> String {
        "Linux".to_string()
    }

    fn os_version(&self) -> String {
        // TODO: Get actual Linux version from /etc/os-release
        "Unknown".to_string()
    }

    fn hostname(&self) -> String {
        // TODO: Get actual hostname
        "localhost".to_string()
    }
}
