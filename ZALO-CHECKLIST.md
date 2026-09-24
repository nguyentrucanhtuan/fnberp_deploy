# Checklist bật kênh đặt hàng Zalo cho một quán

Dùng khi quán **có bật Zalo Mini App đặt hàng** (epic 054). Quán không bật kênh Zalo thì
bỏ qua toàn bộ tệp này.

Hai phần:

- **A — Hạ tầng** (P1-M03): cổng vào, HTTPS, gác IP, địa chỉ người gọi. Làm trên máy chủ.
- **B — Triển khai trong ERP** (P1-M04): quyền, loại đơn, máy in, phương thức thanh toán,
  Thiết lập kênh Zalo, portal Zalo, mini app. Làm trên giao diện.

Mỗi dòng có **cách kiểm quan sát được** (một lệnh, hoặc một thứ nhìn thấy trên màn hình) và
một **ô ghi kết quả**. Ô trống = chưa kiểm. Không đánh dấu ✅ cho mục chưa tự tay nhìn thấy —
cả hai phần dưới đây hỏng theo kiểu **im lặng**: khách trả tiền xong mà quán không thấy đơn,
hoặc tab ZALO không hiện cho đúng người, và không ai báo lỗi cho bạn.

> **Cách dùng:** chép nguyên hai bảng vào hồ sơ quán `DEPLOY-<TÊN-QUÁN>-<IP>.md` (repo
> `fnberp_fullstack`, PRIVATE) rồi điền ở đó. **Đừng điền vào tệp này** — `fnberp_deploy` là
> repo PUBLIC (lệnh cài `curl | bash` đọc thẳng từ `raw.githubusercontent.com`), không được
> chứa IP, tên máy, tài khoản hay khoá của quán nào.

---

## A. Hạ tầng — máy chủ và cổng vào (P1-M03)

Làm trên máy chủ của quán, trong thư mục cài đặt (`~/fnberp` nếu cài bằng
`install/erp.sh`).

| # | Việc | Cách kiểm (quan sát được) | Kết quả |
|---|---|---|---|
| A1 | **Máy chủ đặt tại Việt Nam** | `curl -s https://ipinfo.io/$(curl -s ifconfig.me) \| grep country` → `"country": "VN"`. Máy đặt ngoài VN thì Zalo có thể không gọi tới được, và độ trễ làm khách bỏ giỏ. | |
| A2 | **Có tên miền + HTTPS thật** | `.env` có `SITE_ADDRESS=<domain>` (không phải `:80`); `curl -sI https://<domain>/ \| head -1` → **`HTTP/2 307`** (hệ KHOẺ đẩy người chưa đăng nhập về `/sign-in`). Điều cần thấy là **`HTTP/2` + một mã trả lời**, nghĩa là TLS đã bắt tay xong và Caddy đã trả lời — không phải con số 200. Muốn thấy 200 thì gọi `https://<domain>/sign-in`. Zalo chỉ gọi ngược qua HTTPS; IP LAN hay `http://` là không dùng được. *(307 ở ĐÂY là bình thường; 307 ở A5 mới là hỏng — ở đó nó nghĩa là lượt gọi của Zalo bị Next.js nuốt.)* | |
| A3 | **DNS trỏ đúng máy và cổng 80/443 mở ra internet** | `dig +short <domain>` = IP công khai của máy; `curl -sI http://<domain>/` không timeout. Thiếu cổng 80 là Caddy không xin được chứng chỉ. | |
| A4 | **Ảnh đang chạy có khối `@zalo`** | `docker compose exec caddy grep -c 'handle @zalo' /etc/caddy/Caddyfile` → `1`. ⚠️ **Đừng grep `'zalo-checkout'`**: chuỗi đó có mặt ngay ở dòng mục lục đầu tệp, nên phép kiểm sẽ XANH cả khi khối `handle @zalo` bị xoá sạch. Và kể cả thấy khối, **có dòng trong tệp không chứng minh được THỨ TỰ** — `handle` loại trừ lẫn nhau, một khối chèn lên trên là Zalo rơi vào Next.js. **A5 mới là phép kiểm quyết định.** Ở máy phát hành, chạy `bash install/check-config.sh` để kiểm thứ tự tự động. | |
| A5 | **Đường đó thật sự về backend, không về frontend** | Từ ngoài: `curl -sk -X POST https://<domain>/zalo-checkout/notify -H 'content-type: application/json' -d '{}'` → nhận **JSON của backend** (mã lỗi chữ ký/tham số), **không** phải HTML đăng nhập của Next.js và **không** phải 307. | |
| A6 | **Cổng 3333 KHÔNG mở ra ngoài** | `docker compose ps` — dòng `backend` cột PORTS **trống**. Mở cổng đó là mở một lối vào không qua Caddy, và rào chống dò mật khẩu thành đồ trang trí. | |
| A7 | **`TRUST_PROXY` đúng** | Quán chạy thẳng sau Caddy: `.env` để **TRỐNG** (mặc định đã phủ mạng nội bộ Docker). Quán chạy sau **thêm một lớp** (Cloudflare, ngrok, Tailscale Funnel) thì khai đúng dải của lớp đó, **ngăn cách bằng DẤU PHẨY**. Kiểm: `docker compose logs backend \| grep -i trust` không có cảnh báo lùi-về-mặc-định. ⚠️ Quán có lớp proxy đứng trước Caddy thì **A9 phải ĐỂ TRỐNG `ZALO_ALLOWED_IPS`** — đọc ô A9 trước khi làm. | |
| A8 | **Đo IP thật mà Zalo dùng để gọi** | Sau khi chạy thử một đơn sandbox: `docker compose exec caddy grep zalo-checkout /data/access.log*` → đọc `remote_ip` ở mỗi dòng. Ghi lại **đủ các IP thấy được**, đừng chỉ lấy một, và **chép ngay dòng log vào `DEPLOY-<QUÁN>-<IP>.md`** — log cuốn ở 10 MiB / giữ 3 tệp, để hôm sau là mất bằng chứng. | |
| A9 | **Hẹp `ZALO_ALLOWED_IPS` theo IP đã đo** *(tuỳ chọn — bỏ qua được)* | Chỉ làm sau khi đã đo ở A8. Trình tự **bắt buộc theo đúng thứ tự này**:<br>① Điền dải vào `.env`, **cách nhau bằng DẤU CÁCH** — ⚠️ biến hàng xóm `TRUST_PROXY` lại dùng **dấu phẩy**, hai quy ước ngược nhau, đừng chép nhầm.<br>② **Giữ `::/0` trong danh sách** nếu lượt chạy thử chỉ thấy IP v4 (ví dụ `203.0.113.0/24 ::/0`) — bỏ v6 thì ngày Zalo gọi qua IPv6 sẽ ăn 403 im lặng.<br>③ **`docker compose run --rm caddy caddy validate --config /etc/caddy/Caddyfile` → `Valid configuration`, TRƯỚC khi khởi động lại.** Một dấu phẩy hay CIDR hỏng là Caddy **không nạp được cấu hình** (`parsing CIDR expression … bad bits after slash`), mà Caddy là cổng vào **DUY NHẤT** ⇒ mất **CẢ POS, trang quản trị và đường máy in `/bridge/*`**, không chỉ Zalo.<br>④ `docker compose up -d caddy` → rồi làm **A9b ngay**.<br>**Đường lùi khi đã lỡ:** xoá giá trị `ZALO_ALLOWED_IPS` trong `.env` cho về rỗng → `docker compose up -d caddy`.<br>⚠️ **Quán chạy sau một lớp proxy nữa** (Cloudflare, ngrok, Tailscale Funnel — xem A7): **ĐỂ TRỐNG biến này.** `remote_ip` so địa chỉ **đối tác trực tiếp** của Caddy, không đọc `X-Forwarded-For`: điền IP của Zalo = chặn **100%** callback; điền IP của tunnel = cổng gác thành đồ trang trí vì cả internet qua tunnel đều lọt. Muốn gác thật thì đổi `remote_ip` → `client_ip` **và** khai `trusted_proxies` đúng dải tunnel.<br>Khai sai/thiếu dải = chặn nhầm Zalo = **mất đơn khách đã trả tiền**; để trống còn an toàn hơn đoán, vì cửa này vẫn phải qua kiểm chữ ký HMAC ở backend. | |
| A9b | **Kiểm CHIỀU CHO ngay sau A9 — đừng chỉ kiểm chiều cấm** | Ba trạng thái rất khác nhau — *chặn đúng* · *chặn sạch do gõ nhầm dải* · *Caddy đã chết* — đều cho **cùng một quan sát** "ngoài không vào được", nên tick xanh theo chiều cấm là tự lừa mình. Phải thấy đủ hai thứ:<br>① `docker compose ps caddy` → `running`, **không phải `restarting`** (và `docker compose logs --tail=20 caddy` không có dòng `Error:`).<br>② Một lượt gọi **từ TRONG dải** vẫn tới được backend — gọi lại A5 từ máy trong dải, hoặc đặt thêm **một đơn sandbox nữa** và thấy nó lên POS.<br>Chưa thấy đủ hai thứ thì coi như A9 **chưa xong**, và dùng đường lùi ở A9. | |
| A10 | **Lượt bị chặn có để lại dấu vết** | Ngay sau lượt 403 ở A9: `docker compose exec caddy grep zalo-checkout /data/access.log*` → có dòng với **status 403** và IP của máy vừa gọi. Không có dòng nào = không tra được về sau khi Zalo kêu "gọi không tới". ⚠️ Log **cuốn ở 10 MiB và chỉ giữ 3 tệp** (`roll_size`/`roll_keep`), quán đông thì vài ngày là mất — nên grep **cả tệp đã cuốn** (`/data/access.log*`) và **chép NGAY dòng log khớp vào `DEPLOY-<QUÁN>-<IP>.md` lúc còn nhìn thấy**, đừng hẹn hôm sau. | |
| A11 | **`ZALO_APP_SECRET` có trong `.env`** | `grep -c '^ZALO_APP_SECRET=.\+' .env` → `1`. Đây là khoá giải mã số điện thoại khách (Zalo Graph); thiếu thì route lấy SĐT trả 503 (fails-closed, không bịa số). Khoá này **chỉ ở biến môi trường**, không có ô trong màn Thiết lập. | |
| A12 | **`ZALO_CHECKOUT_API_BASE` đúng chế độ đang chạy** | Chạy thử sandbox → điền gốc sandbox; chạy thật → **để TRỐNG** (gọi Zalo thật). Kiểm biến đã tới được container: `docker compose exec backend printenv ZALO_CHECKOUT_API_BASE`. | |
| A13 | **Sao lưu tự động đang chạy** | README §7. Kênh Zalo ghi thêm đơn và bút toán tiền — mất dữ liệu ở đây là mất tiền đã thu. | |

---

## B. Triển khai trong ERP và trên portal Zalo (P1-M04)

Làm bằng tài khoản quản trị trên giao diện của quán.

| # | Việc | Cách kiểm (quan sát được) | Kết quả |
|---|---|---|---|
| B1 | **Cấp `zalo_orders.read` + `zalo_orders.update` cho nhóm đang chạy** | Người dùng → Nhóm người dùng → nhóm thu ngân đang dùng → tick **Đơn Zalo · Xem + Sửa**. Seed nhóm mẫu là **chỉ-tạo-khi-chưa-có**, nên quán đang chạy **không tự nhận** hai mã này. | |
| B2 | **Log khởi động hết cảnh báo thiếu quyền** | `docker compose logs backend \| grep 'THIẾU'` → **không còn dòng nào** nhắc `zalo_orders`. Còn dòng đó = tab ZALO không bao giờ hiện cho người cần, mà hỏng theo kiểu "không có tab", không theo kiểu có lỗi. | |
| B3 | **Đăng nhập bằng một tài khoản thu ngân thật, thấy tab ZALO** | Vào POS bằng tài khoản của quán (không phải quản trị) → tab **ZALO** có mặt trong hộp đơn. | |
| B4 | **Loại đơn cũ "ZALO APP" đổi tên tay thành "ZALO"** | Cấu hình → Loại đơn: nếu có dòng tên `ZALO APP` (do BFF 046 tạo ở quán cũ) thì **sửa tên** thành `ZALO`. Code **cố ý không** tự đổi bằng migration. Bỏ bước này là quán có hai loại đơn cho cùng một kênh, báo cáo tách đôi. | |
| B5 | **Loại đơn "ZALO" tồn tại** | Cấu hình → Loại đơn có đúng **một** dòng `ZALO`. Hệ tự tạo ở lượt xác nhận đầu tiên nếu chưa có (so `LOWER(name) = 'zalo'`, kể cả bản đã lưu trữ). | |
| B6 | **Khai loại đơn "ZALO" ở MỌI máy in đã khai loại đơn** | Cấu hình → Máy in → từng máy in có danh sách loại đơn: thêm `ZALO`. Máy in nào để trống danh sách thì nhận mọi loại, không phải sửa. | |
| B7 | **Đơn thử không bật cờ `no_printer`** | Xác nhận một đơn Zalo thử → phản hồi có `no_printer: false` (và phiếu bếp/tem **in ra thật**). Cờ `true` nghĩa là **không máy in nào nhận** đơn loại `ZALO` — quay lại B6. *(Tên cờ đúng là `no_printer`, không phải `no_printer_matched` như bản epics cũ ghi.)* | |
| B8 | **Nhập Mini App ID ở Thiết lập** | Thiết lập → **Đặt hàng Zalo** → ô *Mini App ID*. Đây là thứ hệ dùng để giải "lượt gọi này của quán nào"; sai là mọi callback bị từ chối. | |
| B9 | **Nhập PrivateKey Checkout ở Thiết lập** | Cùng màn, ô *PrivateKey*. Ô này **chỉ-ghi**: lưu xong không bao giờ đọc lại được, và để trống lúc lưu thì **giữ khoá cũ**. Kiểm gián tiếp bằng B14 (đơn thử chạy được). | |
| B10 | **Chọn quầy mặc định nhận đơn Zalo** | Cùng màn, ô *Quầy mặc định*. Đơn khách đặt hiện ở hộp đơn của đúng quầy này. | |
| B11 | **Đặt phí ship + ngưỡng miễn phí ship** | Cùng màn. **Chưa đặt phí ship thì hình thức giao hàng bị tắt** — khách chỉ đặt được mang đi/tại bàn. | |
| B12 | **Nhập "Số điện thoại quán"** | Cùng màn. Bỏ trống thì khách **không thấy dòng SĐT** khi đơn bị từ chối hoặc chờ quá lâu — hệ không bịa số. | |
| B13 | **Lưu Thiết lập lần đầu → PTTT `ZALO` được tạo** | Cấu hình → Phương thức thanh toán: có dòng **ZALO**. | |
| B14 | **PTTT `ZALO` KHÔNG hiện ở danh sách của quầy** | Mở màn thanh toán ở POS → ô chọn phương thức **không có** `ZALO` (`show_in_pos = false`). Hiện ra là thu ngân chọn nhầm cho đơn tiền mặt, và tiền cổng lọt vào đối soát két. | |
| B14b | **Khai Callback URL và notify URL của QUÁN NÀY trên Zalo Portal** | Portal Zalo → Mini App của quán → khai `https://<domain-quán>/zalo-checkout/callback` và `https://<domain-quán>/zalo-checkout/notify`. **Mỗi quán một Mini App với Callback URL và PrivateKey riêng** (SPEC §Cửa công khai). ⚠️ Bỏ bước này ở quán thứ hai là portal vẫn trỏ tên miền quán CŨ: quán mới tick sạch A1–A13 + B1–B18 mà khách trả tiền xong **callback không bao giờ tới**, đơn treo Chờ Checkout, không bút toán nào, màn hình không báo gì. Cách kiểm: sau một đơn thử, `docker compose exec caddy grep zalo-checkout /data/access.log*` **trên máy quán này** có dòng `/zalo-checkout/callback`. | |
| B15 | **Tắt phương thức BANK trên Zalo Portal** | Portal Zalo → Mini App → Thanh toán: **BANK tắt**. Bật mà quán chưa đối soát được là tiền về tài khoản nhưng đơn không tự chốt. | |
| B16 | **Deploy mini app đúng một bản cho quán này** | Theo `trcf_mini_app/DEPLOY_ZALO.md` (một bản build = một quán). Bảng B0 của tệp đó **chỉ liệt kê màu và tên** — chưa đủ. Phải đổi thêm, **bắt buộc cho mỗi quán**:<br>① **`trcf_mini_app/.env.production` → `VITE_API_URL=https://<domain-quán-này>`** (đang ghim cứng `https://pos.coffeetreepos.io.vn`);<br>② `VITE_ZALO_REQUEST_PHONE` theo quán;<br>③ **domain tin cậy trên Zalo Portal** = domain của quán này.<br>⚠️ Làm đúng bốn chỗ màu/tên mà bỏ `VITE_API_URL` thì mini app quán B **gọi backend quán A**: đơn và tiền ZaloPay của khách quán B rơi vào quán A.<br>**Cách kiểm phải neo vào dữ liệu RIÊNG của quán này** — mở mini app, tìm **một món chỉ quán này có** (hoặc một giá chỉ quán này đặt) và thấy nó. ⚠️ **Đừng kiểm bằng "thấy tên và logo của quán"**: tên/logo đọc lúc chạy từ `/shop/info`, nên nếu app đang trỏ nhầm backend quán A thì nó hiện tên quán A — mà ở quán A thì phép kiểm đó vẫn XANH. | |
| B17 | **Chạy đủ bộ test trước khi đẩy bản mới cho quán** | `cd trcf_erp_backend && pnpm test` · `pnpm test:e2e` · `cd trcf_mini_app && npm run lint && npm run test`. **Ghi số ca vào hồ sơ quán.** ⚠️ Kiểm `ps aux \| grep jest` trước khi tin một con số `test:e2e` — DB test dùng chung, hai lượt chạy song song sinh cả đỏ giả lẫn xanh giả. | |
| B18 | **Chạy thử trọn hai đơn thật (sandbox)** | Một đơn giao hàng trả ZaloPay + một đơn COD, trên điện thoại thật với mã phương thức `_SANDBOX`. Kết quả đo ghi vào bảng P1-M01/P1-M02/P3-002 của `_bmad-output/specs/spec-zalo-mini-app-dat-hang/kiem-chung.md`. | |

---

## Sau khi chạy thử xong — TRƯỚC khi quán bán thật

1. **GỠ QUÁN RA KHỎI SANDBOX.** A12 đưa quán *vào* sandbox nhưng không có bước đưa *ra*.
   Bán thật mà `ZALO_CHECKOUT_API_BASE` còn trỏ sandbox thì `get-status` (lưới tìm lại tiền
   khi callback lỡ) và `updateOrderStatus` đi **hỏi sandbox về đơn thật** ⇒ lưới an toàn tiền
   **chết câm**, triệu chứng duy nhất nằm trong `docker compose logs backend`.
   - Xoá giá trị `ZALO_CHECKOUT_API_BASE` trong `.env` cho về rỗng → `docker compose up -d backend`
   - Kiểm: `docker compose exec backend printenv ZALO_CHECKOUT_API_BASE` → **in ra dòng trống**
2. **Chạy lại A5** (lượt gọi `/zalo-checkout/*` từ ngoài về đúng backend) sau mọi lần đổi
   `.env` hoặc khởi động lại — đây là phép kiểm quyết định của cả phần A.
3. Điền **A8 → A9 → A9b → A10** (đo IP thật · hẹp allowlist · **kiểm chiều CHO** · dấu vết
   403). Trước khi đo xong thì cứ để `ZALO_ALLOWED_IPS` **trống** — mở còn hơn chặn nhầm; và
   quán có lớp proxy trước Caddy thì để trống **hẳn**.
4. Điền kết quả đo vào `kiem-chung.md` §2 (P1-M01, P1-M02, P3-002). **Ô nào chưa đo thì ghi
   thẳng "chưa đo"**, đừng suy ra từ ca giả lập.
5. Chép bảng A + B đã điền vào `DEPLOY-<TÊN-QUÁN>-<IP>.md` kèm ngày giờ, **kèm dòng log đã
   chép ở A8/A10** (log cuốn, để sau là mất).
