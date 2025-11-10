use anyhow::Result;
use ring::signature;
use std::fs;
use std::path::Path;

mod signing;

/// Verify binary signature
pub fn verify_signature(binary_path: &Path, signature_path: &Path, public_key: &[u8]) -> Result<bool> {
    let binary_data = fs::read(binary_path)?;
    let signature_data = fs::read(signature_path)?;
    
    let public_key = signature::UnparsedPublicKey::new(
        &signature::ED25519,
        public_key,
    );
    
    match public_key.verify(&binary_data, &signature_data) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}

/// Generate random agent key
pub fn generate_agent_key() -> String {
    use ring::rand::{SystemRandom, SecureRandom};
    
    let rng = SystemRandom::new();
    let mut key = vec![0u8; 32];
    rng.fill(&mut key).unwrap();
    
    base64::encode(&key)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_agent_key() {
        let key1 = generate_agent_key();
        let key2 = generate_agent_key();
        
        assert_ne!(key1, key2);
        assert_eq!(key1.len(), 44); // base64 encoded 32 bytes
    }
}
