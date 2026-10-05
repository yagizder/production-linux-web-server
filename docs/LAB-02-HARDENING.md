# LAB 02 — Production Linux Server Hardening

## Problem

LAB 01 sonunda çalışan ve reboot sonrasında erişilebilir bir Ubuntu/Nginx web
sunucusu vardı. Ancak çalışan bir servis otomatik olarak güvenli bir servis
anlamına gelmiyordu. SSH parola girişine izin veriyor, root için key tabanlı
giriş ihtimali tamamen kapanmamıştı, kullanılmayan forwarding özellikleri ve
servisler açıktı ve brute-force denemelerini izleyen bir katman yoktu.

Bu aşamanın hedefi sistemi olabildiğince çok ayar kapatılmış hâle getirmek değil,
gerçek kullanım ihtiyacını korurken saldırı yüzeyini azaltmaktı.

## Güvenli çalışma yöntemi

SSH ayarı değiştirmek erişim kaybı riski taşır. Değişiklikten önce VMware
snapshot alındı, VMware console girişi doğrulandı ve çalışan SSH oturumundan
bağımsız ikinci bir key oturumu test edildi. Mevcut oturum, yeni politika ile
yeni bağlantı kurulmadan kapatılmadı.

Her config değişikliğinde şu sıra izlendi:

```text
mevcut durumu ölç
→ küçük ve amaçlı değişiklik yap
→ syntax/effective config kontrol et
→ servisi reload/restart et
→ yeni davranışı ayrı bağlantıyla doğrula
→ logları incele
→ reboot sonrasında tekrar doğrula
```

## SSH hardening

Ubuntu, ana `sshd_config` dosyasına ek olarak `sshd_config.d/*.conf` drop-in
dosyalarını okur. Parolalı girişin `50-cloud-init.conf` tarafından açıldığı
görüldü. Cloud-init tarafından yönetilen dosyayı değiştirmek yerine daha önce
okunan `00-lab-hardening.conf` oluşturuldu.

Politika root ve parola girişini kapattı, public-key erişimini korudu, kullanıcıyı
`yagiz` ile sınırlandırdı, kullanılmayan forwarding özelliklerini kapattı,
deneme/grace-time değerlerini düşürdü ve log seviyesini yükseltti.

`sshd -t` syntax hatası olmadığını, `sshd -T` ise include ve varsayımlar sonrası
gerçek etkili değerleri kanıtladı. Reload sonrasında Ed25519 key ile yeni oturum
açılırken password-only bağlantı reddedildi.

## Least privilege

Kullanıcı ve grup denetiminde tek normal kullanıcı `yagiz` idi. Yönetim için
sudo yetkisi gerekliydi ve korundu. Root parolası kilitliydi. Kullanıcı `lxd`
grubundaydı fakat gerçek LXD snap/daemon kurulu değildi; yalnızca installer
wrapper bulunuyordu. Gereksiz ve yüksek yetkili grup üyeliği kaldırıldı.

Kritik sistem, sudo ve SSH dosyalarının sahiplik/mod değerleri zaten güvenliydi.
Kanıt olmadan permission değiştirmek yerine mevcut doğru politika korundu.

## Servis ve port audit

TCP dinleyicileri yalnızca SSH ve Nginx'ten oluşuyordu; DNS loopback ile
sınırlıydı. UDP tarafında DHCP istemcisi, local DNS ve local Chrony soketleri
görüldü. Bunlar sistemin ağ ve zaman işlevleri için gerekliydi.

VM'nin modem veya enterprise multipath storage ihtiyacı olmadığı için
`ModemManager` ve `multipathd` durdurulup boot başlangıçları kapatıldı. Paketler
silinmedi; böylece karar gerektiğinde kolayca geri alınabilir kaldı.

## Fail2ban ve log audit

Fail2ban için ayrı `sshd.local` dosyası oluşturuldu. Politika, systemd journal
üzerinden SSH başarısızlıklarını izleyip 10 dakika içinde 5 denemeye ulaşan IP'yi
10 dakika engelleyecek şekilde tanımlandı. Config testi başarılıydı ve `sshd`
jail aktifti.

SSH loglarında hardening öncesi `Accepted password`, sonrasında ise
`Accepted publickey` kayıtları görüldü. Bu, config dosyasının varlığından daha
güçlü bir davranış kanıtı sağladı. Fail2ban logları temiz restart ve `Server
ready` durumunu gösterdi.

Otomatik ban eşiği ayrı bir saldırı istemcisiyle tetiklenmedi. Bu sınırlama
raporda açıkça tutuldu.

## Son kabul testi

Sunucu reboot edildi ve Windows istemcisinden private key kullanılarak yeniden
bağlanıldı. SSH, Nginx ve Fail2ban aktifti. `PasswordAuthentication no`,
`PermitRootLogin no`, aktif `sshd` jail ve kapalı gereksiz servisler yeniden
doğrulandı.

Bu test, politikanın yalnızca çalışan oturumda değil, boot sonrasında da kalıcı
olduğunu gösterdi.

## Sonuç

Sunucu işlevini kaybetmeden daha dar bir erişim ve servis yüzeyine geçti. En
önemli kazanım tek bir ayar değil, uygulanan yöntemdi: baseline almak, geri
dönüş yolu hazırlamak, yönetilen dosyaları doğrudan değiştirmemek, etkili
config'i ölçmek, davranışı ve logları doğrulamak ve yapılmayan testler hakkında
iddiada bulunmamak.
