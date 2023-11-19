use QLNhaSach
go
-- Tạo Func tìm kiếm sách
--a/ Tìm kiếm sách theo tên
CREATE FUNCTION TimKiemSachTheoTen
    (@TenSach NVARCHAR(100))
RETURNS TABLE
AS
RETURN
    SELECT *
    FROM Sach
    WHERE TenSach LIKE '%' + @TenSach + '%'
GO
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
--c/ Tìm kiếm sách theo thể loại
CREATE FUNCTION TimKiemSachTheoTheLoai
    (@TenTheLoai NVARCHAR(50))
RETURNS TABLE
AS
RETURN
    SELECT *
    FROM Sach
    WHERE TheLoai LIKE '%' + @TenTheLoai + '%'
GO
--d/ Tìm kiếm sách theo giá
CREATE FUNCTION TimKiemSachTheoGia
    (@GiaMin MONEY,
     @GiaMax MONEY)
RETURNS TABLE
AS
RETURN
    SELECT *
    FROM Sach
    WHERE Gia BETWEEN @GiaMin AND @GiaMax


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
