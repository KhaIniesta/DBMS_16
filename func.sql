use QLNhaSach
go
-- Tạo Func tìm kiếm sách
--b/ Tìm kiếm sách theo tác giả
CREATE FUNCTION TimKiemSachTheoTacGia
    (@TenTacGia NVARCHAR(50))
RETURNS TABLE
AS
RETURN
    SELECT Sach.*
    FROM Sach
    INNER JOIN TacGia ON Sach.MaTG = TacGia.MaTG
    WHERE TacGia.TenTG LIKE '%' + @TenTacGia + '%'
GO

--4.1 func tính doanh thu theo ngày tháng năm
go
CREATE FUNCTION func_tinhDoanhThuNgay(@ngay INT, @thang INT, @nam INT)
RETURNS FLOAT
	AS
	BEGIN
		 DECLARE @doanhThu FLOAT = 0;
		 SELECT @doanhThu = COALESCE(SUM(TongHD), 0)
		 FROM HoaDon
		 WHERE DAY(NgayInHD) = @ngay AND MONTH(NgayInHD) = @thang AND YEAR(NgayInHD) = @nam;
	 RETURN @doanhThu;
END;
go
CREATE FUNCTION func_tinhDoanhThuThang(@thang INT, @nam INT) 
RETURNS float
BEGIN
	 DECLARE @doanhThu float = 0;
	 SELECT @doanhthu = COALESCE(SUM(TongHD), 0)
	 FROM HoaDon
	 WHERE MONTH(NgayInHD) = @thang AND YEAR(NgayInHD) = @nam;
	 RETURN @doanhThu;
END;
go
CREATE FUNCTION func_tinhDoanhThuNam(@nam INT) 
RETURNS float
BEGIN
	DECLARE @doanhThu float = 0;
	 SELECT @doanhthu = COALESCE(SUM(TongHD), 0)
	 FROM HoaDon
	 WHERE YEAR(NgayInHD) = @nam;
	 RETURN @doanhThu;
END;


-- PHẦN FUNCTION =================================================================================
-- 1. Function lấy bảng sách
GO
CREATE FUNCTION Func_LayBangSach()
RETURNS TABLE
AS 
	RETURN (SELECT * FROM Sach)


-- 2. Function lấy bảng phiếu nhập
GO
CREATE FUNCTION Func_LayBangPhieuNhap()
RETURNS TABLE
AS 
	RETURN (SELECT * FROM PhieuNhap)


Go
CREATE FUNCTION func_DangNhap(@TenDangNhap varchar(50), @MatKhau varchar(50))
RETURNS INT
	AS
	BEGIN
		 DECLARE @Cap int = 0;
		 SELECT @Cap = Cap
		 FROM TaiKhoan
		 WHERE TenDangNhap = @TenDangNhap AND MatKhau = @MatKhau
	RETURN @Cap;
END;