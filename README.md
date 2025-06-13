<h1>Phân chia công việc:</h1>

- Trí Bằng: Đã kết nối được mysql database với Django và hoàn tất phần filter attribute

- Tú: Thêm logic phần Discount Program và sửa Checkout/Bán Hàng

- Playlist video: https://www.youtube.com/playlist?list=PL-51WBLyFTg0omnamUjL1TCVov7yDTRng

Deadline hiện tại:<strong> 07/12/2024 </strong>

Thông tin mới:
- Sửa lại cách vận động của Checkout và Payment dựa trên database mysql của Bảo.
- Sản phẩm secondhand sẽ được giảm giá vào database product. -> Không cần chỉnh backend
- Discount Program -> Giảm giá thẳng vào database -> Hiển thị tất cả discount program đc áp dụng lên sản phẩm.

Note: 
- Mỗi sản phẩm trong database đều có ID riêng (VD: Có 3 laptop tên "Laptop A" trong kho thì cả 3 cái đều có id khác nhau), chức năng Cart hiện tại đối xử với chúng như là có cùng ID.
- Link video hướng dẫn cách kết nối mysql database với Django: https://www.youtube.com/watch?v=5g_xIwxLSJk&t=7s&pp=ygUiY29ubmVjdCBkamFuZ28gd2l0aCBteXNxbCBkYXRhYmFzZQ%3D%3D

Trí Bằng:
- Tối ưu hóa Filtering hơn. (ascending/descending by price)
- Chỉnh cập nhật thông tin -> Đã sửa xong.

Tú:
- Sửa phần Checkout/Mua hàng => Transaction -> Finished. Payment_method -> Cash / Card / E-Money
-> Đã có thể mua hàng và lưu payment method, nhưng mà logic Transaction còn sai. Transaction hiện tại chứa ID của khách hàng phải thay đổi, chứ không phải tạo cái Transaction mới.
- laptop -> P_ID của applies -> D_ID -> Discount Program -> list[str]
- Cột P_ID của applies sẽ liên kết với cột ID của những sản phâm, từ đó mình tìm ra những loại discount.
- Lưu ý: Khi checkout hoàn thành xong món hàng thì phải đăng xuất khỏi tài khoản customer.
