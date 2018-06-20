Add-VpnConnection -Name "micou_US_VPN" -ServerAddress "micou.top" -TunnelType IKEv2 -EncryptionLevel Maximum -AuthenticationMethod EAP

Set-VpnConnectionIPsecConfiguration -ConnectionName "micou_US_VPN" -AuthenticationTransformConstants GCMAES256 -CipherTransformConstants GCMAES256 -EncryptionMethod AES256 -IntegrityCheckMethod SHA256 -DHGroup ECP384 -PfsGroup ECP384 -Force