-- PHẦN VIEW =================================================================================
use QLNhaSach
-- 1. Xem các thông tin sách trong kho
GO
CREATE VIEW V_ThongTinSachTrongKho AS
SELECT s.MaTG, s.MaNXB, s.TenSach, s.SoLuongSach, s.Gia, s.TheLoai , ctpn.MaPhieuNhap, ctpn.SoLuongNhap
FROM Sach s INNER JOIN ChiTietPhieuNhap ctpn ON s.MaSach = ctpn.MaSach
GO

-- 2. Xem chi tiết các hóa đơn
CREATE VIEW V_ChiTietCacHoaDon AS
SELECT hd.TongHD, hd.NgayInHD, cthd.MaSach, cthd.SoLuongBan, cthd.Gia
FROM HoaDon hd INNER JOIN ChiTietHoaDon cthd ON hd.MaHD = cthd.MaHD
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

-- 5. View xem so luong sach da ban trong ngay 
create view V_SoLuongSachBanTrongNgay as
select ChiTietHoaDon.MaSach,sum(SoLuongBan) TongSoLuongBan from HoaDon join ChiTietHoaDon on HoaDon.MaHD = ChiTietHoaDon.MaHD 
where (select cast(NgayInHD as date) ngayInHD from HoaDon) = cast(GetDate() as date) group by ChiTietHoaDon.MaSach
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