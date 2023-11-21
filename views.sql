-- PHẦN VIEW =================================================================================
use QLNhaSach
-- 1. Xem các thông tin sách trong kho
GO
-- 3. Xem chi tiết các phiếu nhập
CREATE VIEW V_ChiTietCacPhieuNhap AS
SELECT pn.MaPhieuNhap, pn.MaNXB, pn.NgayNhap, ctpn.MaSach, ctpn.SoLuongNhap
FROM PhieuNhap pn INNER JOIN ChiTietPhieuNhap ctpn ON pn.MaPhieuNhap = ctpn.MaPhieuNhap
GO

-- 4.a View xuat tong doanh thu theo ngay

create view V_DTNgay as
select MaHD, Year(NgayInHD) Nam, Month(NgayInHD) Thang, Day(NgayInHD) Ngay, TongHD from HoaDon
go

-- 4.b View xuat tong doanh thu theo thang
create view V_DTThang as
select MaHD, Year(NgayInHD) Nam, Month(NgayInHD) Thang, Day(NgayInHD) Ngay, TongHD from HoaDon
go

-- 4.c View xuat tong doanh thu theo nam
create view V_DTNam as
select MaHD, Year(NgayInHD) Nam, Month(NgayInHD) Thang, TongHD from HoaDon
go

-- 6. View hiển thị chi tiết sách trong chi tiết hóa đơn
create view V_HienChiTietSach
as
	select top(99.99) percent Sach.MaSach, TacGia.TenTG, NhaXuatBan.TenNXB, Sach.TheLoai, Sach.SoLuongSach, Sach.Gia, Sach.TenSach, Sach.Anh
	from Sach join ChiTietHoaDon on Sach.MaSach = ChiTietHoaDon.MaSach 
	join HoaDon on ChiTietHoaDon.MaHD = HoaDon.MaHD 
	join TacGia on Sach.MaTG = TacGia.MaTG
	join NhaXuatBan on Sach.MaNXB = NhaXuatBan.MaNXB
	order by Sach.TenSach
go