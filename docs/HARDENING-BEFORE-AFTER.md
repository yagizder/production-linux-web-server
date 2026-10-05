# Hardening Öncesi ve Sonrası

Bu karşılaştırma, web sunucusu kurulduktan sonraki baseline ile LAB 02 sonunda
doğrulanan etkili durumu gösterir.

| Kontrol | Önce | Sonra | Güvenlik etkisi |
| --- | --- | --- | --- |
| Root SSH | `prohibit-password` | `no` | Root için bütün doğrudan SSH girişleri kapandı |
| Parolalı SSH | `yes` | `no` | Parola tahmini yoluyla uzaktan giriş kapandı |
| Public-key SSH | `yes` | `yes` | Yönetim için doğrulanmış anahtar erişimi korundu |
| Keyboard interactive | `no` | `no` | Kapalı durum korundu |
| Empty password | `no` | `no` | Boş parola girişi kapalı kaldı |
| Maksimum deneme | `6` | `3` | Bağlantı başına deneme yüzeyi daraldı |
| Login grace time | `120s` | `30s` | Yarım açık authentication süresi azaldı |
| X11 forwarding | `yes` | `no` | Kullanılmayan grafik yönlendirme kapandı |
| Agent forwarding | `yes` | `no` | SSH agent'ın uzak kullanım yolu kapandı |
| TCP forwarding | `yes` | `no` | Sunucunun izinsiz tünel olarak kullanımı sınırlandı |
| SSH kullanıcı sınırı | Yok | `AllowUsers yagiz` | SSH giriş yüzeyi tek yönetim hesabına sınırlandı |
| SSH log seviyesi | `INFO` | `VERBOSE` | Anahtar ve bağlantı olaylarının görünürlüğü arttı |
| Brute-force koruması | Yok | Fail2ban `sshd` jail | Tekrarlanan başarısızlıklar için IP-ban politikası eklendi |
| `lxd` grup üyeliği | `yagiz` üyeydi | Üyelik kaldırıldı | Kullanılmayan yüksek yetki yüzeyi kaldırıldı |
| ModemManager | Aktif | Inactive/disabled | Kullanılmayan daemon kapatıldı |
| multipathd | Aktif | Inactive/disabled | Kullanılmayan storage daemon'ı kapatıldı |
| UFW inbound | Default deny; 22 ve 80 açık | Aynı | Mevcut dar firewall politikası korundu |
| Dış TCP servisleri | SSH 22, HTTP 80 | Aynı | Uygulama gereksinimi dışına yeni port açılmadı |

## Bilinçli olarak değiştirilmeyenler

- Root parolası zaten kilitliydi.
- `.ssh` dizini `700`, `authorized_keys` dosyası `600` idi.
- `/etc/shadow` ve `/etc/sudoers` izinleri güvenli değerlerdeydi.
- UFW default-deny inbound politikası zaten aktifti.
- SSH portu değiştirilmedi; port değiştirmek authentication kontrolünün yerine
  geçmez.
- OpenSSH cipher/MAC/KEX varsayımları elle ezilmedi. Gereksiz özel listeler
  zamanla eskiyebilir ve istemci uyumluluğunu bozabilir.
- Ağ socket'i açmayan servisler yalnızca daha kısa bir servis listesi elde etmek
  için rastgele kapatılmadı.

## Doğrulama sınırı

Fail2ban config testi geçti, servis ve `sshd` jail aktifti. Ayrı bir saldırı
istemcisinden otomatik ban eşiği tetiklenmedi. Bu nedenle sonuç, “Fail2ban
yapılandırıldı ve jail aktif” olarak ifade edilir; “brute-force saldırısı
uçtan uca engellendi” iddiası kullanılmaz.
