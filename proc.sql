-- PHẦN STORED PROCEDURE =================================================================================
-- 1. Tạo Proc CRUD sách
-- 1.a Thêm sách
GO 
CREATE PROCEDURE Proc_ThemSach
	@MaSach NCHAR(10),
	@MaTG NCHAR(10),
	@MaNXB NCHAR(10),
	@TenSach NVARCHAR(100),
	@SoLuongSach INT,
	@Gia MONEY,
    @TheLoai NVARCHAR(50),
    @Anh IMAGE = NULL
AS
BEGIN
	INSERT INTO Sach VALUES(@MaSach, @MaTG, @MaNXB, @TenSach, @SoLuongSach, @Gia, @TheLoai, @Anh)
END

-- 1.b Sửa sách:
GO 
CREATE PROCEDURE Proc_SuaSach
	@MaSach NCHAR(10),
	@MaTG NCHAR(10),
	@MaNXB NCHAR(10),
	@TenSach NVARCHAR(100),
	@SoLuongSach INT,
	@Gia MONEY,
    @TheLoai NVARCHAR(50),
    @Anh IMAGE = NULL
AS
BEGIN
	UPDATE Sach
	SET
		MaTG = @MaTG,
		MaNXB = @MaNXB,
		TenSach = @TenSach,
		SoLuongSach = @SoLuongSach,
		Gia = @Gia,
		TheLoai = @TheLoai,
        Anh = @Anh
	WHERE MaSach = @MaSach
END

-- 1.c Xóa sách:
GO 
CREATE PROCEDURE Proc_XoaSach
	@MaSach NCHAR(10)
AS
BEGIN
	DELETE Sach 
	WHERE MaSach = @MaSach
END

--1.d Hiển thị chi tiết sách
GO
create procedure Proc_HienChiTietSach
as
begin
	select Sach.MaSach, TacGia.TenTG, NhaXuatBan.TenNXB, Sach.TheLoai, Sach.SoLuongSach, Sach.Gia, Sach.TenSach, Sach.Anh
	from Sach join ChiTietHoaDon on Sach.MaSach = ChiTietHoaDon.MaSach 
	join HoaDon on ChiTietHoaDon.MaHD = HoaDon.MaHD 
	join TacGia on Sach.MaTG = TacGia.MaTG
	join NhaXuatBan on Sach.MaNXB = NhaXuatBan.MaNXB
end
go

--1.e Hiển thị sách theo mã sách
create procedure Proc_HienSachtheoMaSach
	@MaSach nchar(10)
as
begin
	select Sach.MaSach, TacGia.TenTG, NhaXuatBan.TenNXB, Sach.TheLoai, Sach.SoLuongSach, Sach.Gia, Sach.TenSach
	from Sach join ChiTietHoaDon on Sach.MaSach = ChiTietHoaDon.MaSach 
	join HoaDon on ChiTietHoaDon.MaHD = HoaDon.MaHD 
	join TacGia on Sach.MaTG = TacGia.MaTG
	join NhaXuatBan on Sach.MaNXB = NhaXuatBan.MaNXB
	where Sach.MaSach = @MaSach
end
go


--4.f Tìm kiếm toàn bộ Mã sách
create procedure Proc_TimKiemMaSach
as
begin
	select distinct MaSach from Sach order by MaSach 
end
go

create procedure Proc_TimKiemTenSach
as
begin
	select TenSach from Sach
end
go
-- 2. Tạo Proc CRUD phiếu nhập
-- 2.a Thêm phiếu nhập
GO 
CREATE PROCEDURE Proc_ThemPhieuNhap
	@MaPhieuNhap NCHAR(10), 
    @MaNXB NCHAR(10), 
    @NgayNhap DATETIME
AS
BEGIN
	INSERT INTO PhieuNhap VALUES(@MaPhieuNhap, @MaNXB, @NgayNhap)
END

-- 2.b Sửa phiếu nhập
GO 
CREATE PROCEDURE Proc_SuaPhieuNhap
	@MaPhieuNhap NCHAR(10), 
    @MaNXB NCHAR(10), 
    @NgayNhap DATETIME
AS
BEGIN
	UPDATE PhieuNhap
	SET
		@MaNXB = @MaNXB, 
		NgayNhap = @NgayNhap
	WHERE MaPhieuNhap = @MaPhieuNhap
END

-- 2.c Xóa phiếu nhập
GO 
CREATE PROCEDURE Proc_XoaPhieuNhap
	@MaPhieuNhap NCHAR(10)
AS
BEGIN
	DELETE PhieuNhap 
	WHERE MaPhieuNhap = @MaPhieuNhap
END

-- 3. Tạo Proc CRUD chi tiết phiếu nhập phiếu nhập
-- 3.a Thêm chi tiết phiếu nhập
GO 
CREATE PROCEDURE Proc_ThemChiTietPhieuNhap
	@MaPhieuNhap NCHAR(10), 
    @MaSach NCHAR(10), 
    @SoLuongNhap INT
AS
BEGIN
	INSERT INTO ChiTietPhieuNhap VALUES(@MaPhieuNhap, @MaSach,  @SoLuongNhap)
END

-- 3.b Sửa chi tiết phiếu nhập
GO 
CREATE PROCEDURE Proc_SuaChiTietPhieuNhap
	@MaPhieuNhap NCHAR(10), 
    @MaSach NCHAR(10), 
    @SoLuongNhap INT
AS
BEGIN
	UPDATE ChiTietPhieuNhap
	SET
		SoLuongNhap = @SoLuongNhap
	WHERE MaPhieuNhap = @MaPhieuNhap AND MaSach = @MaSach
END

-- 3.c Xóa chi tiết phiếu nhập
GO 
CREATE PROCEDURE Proc_XoaChiTietPhieuNhap
	@MaPhieuNhap NCHAR(10), 
    @MaSach NCHAR(10)
AS
BEGIN
	DELETE ChiTietPhieuNhap 
	WHERE MaPhieuNhap = @MaPhieuNhap AND MaSach = @MaSach
END
go
-- 4. Proc cho CRUD bảng HoaDon
-- 4.a Xuất thông tin hóa đơn
create procedure Proc_HienHoaDon 
as
begin
	select * from HoaDon
end
go

--4.b Hiện toàn bộ mã hóa đơn
create procedure Proc_TimKiemMaHD
as
begin
	select distinct MaHD, TongHD from HoaDon order by MaHD 
end
go

--4.c Tìm kiếm theo mã hóa đơn trong bảng hóa đơn
create procedure Proc_TimKiemTheoMaHD
	@MaHD nchar(15)
as
begin
	select TongHD from HoaDon where MaHD = @MaHD
end
go

--4.d Thêm mã hóa đơn
create procedure Proc_ThemMaHoaDon 
as
begin
	declare @MaHD nchar(15), @ngayThang DATE
	set @ngayThang = getDate()
	set @MaHD = 'HD' + format(getdate(), 'yyyyMMddhhmmss')
	insert into HoaDon(MaHD, NgayInHD) values(@MaHD, @ngayThang)

	select MaHD from HoaDon where MaHD = @MaHD
end
go

--4.e Cập nhật hóa đơn
create procedure Proc_CapNhatHoaDon
	@MaHD nchar(15),
	@NgayInHoaDon datetime
as
begin
	update HoaDon set MaHD = @MaHD, NgayInHD = @NgayInHoaDon
end
go

--4.f Xóa hóa đơn
create procedure Proc_XoaHoaDon
	@MaHD nchar(15)
as
begin
	delete from ChiTietHoaDon where MaHD = @MaHD
	delete from HoaDon where MaHD = @MaHD
end
go
--5. Proc cho CRUD bảng ChiTietHoaDon
--5.a Hiển thị chi tiết hóa đơn
create procedure Proc_HienCTHD
as
begin
	select Sach.MaSach , HoaDon.MaHD , TacGia.TenTG, NhaXuatBan.TenNXB, Sach.TheLoai, ChiTietHoaDon.SoLuongBan, Sach.Gia, Sach.TenSach, Sach.Anh
	from Sach join ChiTietHoaDon on Sach.MaSach = ChiTietHoaDon.MaSach
	join HoaDon on ChiTietHoaDon.MaHD = HoaDon.MaHD 
	join TacGia on Sach.MaTG = TacGia.MaTG
	join NhaXuatBan on Sach.MaNXB = NhaXuatBan.MaNXB
end
go

--5.b Hiện CTHD theo mã hóa đơn
create procedure Proc_HienCTHDTheoMaHD @MaHD nchar(15)
as
begin
	select Sach.MaSach, HoaDon.MaHD, TacGia.TenTG, NhaXuatBan.TenNXB, Sach.TheLoai, ChiTietHoaDon.SoLuongBan, Sach.Gia,	Sach.TenSach, Sach.Anh
	from Sach join ChiTietHoaDon on Sach.MaSach = ChiTietHoaDon.MaSach 
	join HoaDon on ChiTietHoaDon.MaHD = HoaDon.MaHD 
	join TacGia on Sach.MaTG = TacGia.MaTG
	join NhaXuatBan on Sach.MaNXB = NhaXuatBan.MaNXB
	where HoaDon.MaHD = @MaHD
end
go

create procedure Proc_HienCTHDTheoTenSach @TenSach nchar(100)
as
begin
	select Sach.MaSach, HoaDon.MaHD, TacGia.TenTG, NhaXuatBan.TenNXB, Sach.TheLoai, ChiTietHoaDon.SoLuongBan, Sach.Gia,	Sach.TenSach, Sach.Anh
	from Sach join ChiTietHoaDon on Sach.MaSach = ChiTietHoaDon.MaSach 
	join HoaDon on ChiTietHoaDon.MaHD = HoaDon.MaHD 
	join TacGia on Sach.MaTG = TacGia.MaTG
	join NhaXuatBan on Sach.MaNXB = NhaXuatBan.MaNXB
	where Sach.TenSach = @TenSach
end
go

--5.c Thêm sách cho chi tiết hóa đơn
create procedure Proc_ThemSachCTHD
	@MaHD nchar(15), 
	@MaSach nchar(10), 
	@SoLuongBan int
as
begin
	begin try
	insert into ChiTietHoaDon(MaHD, MaSach, SoLuongBan) values(@MaHD, @MaSach, @SoLuongBan)
	end try
	begin catch
		declare @err NVARCHAR(MAX)
		select @err = ERROR_MESSAGE()
		raiserror(@err, 16, 1)
	end catch
end
go

--5.d Xóa sách cho chi tiết hóa đơn
create procedure Proc_CapNhatSachCTHD
	@MaHD nchar(15), 
	@MaSach nchar(10), 
	@SoLuongBan int
as
begin
	begin try
	update ChiTietHoaDon set SoLuongBan =  @SoLuongBan where MaHD = @MaHD and MaSach = @MaSach 
	end try
	begin catch
		declare @err NVARCHAR(MAX)
		select @err = ERROR_MESSAGE()
		raiserror(@err, 16, 1)
	end catch
end
go

--5.e Cập nhật sách cho chi tiết hóa đơn
create procedure Proc_XoaSachCTHD
	@MaHD nchar(15),
	@MaSach nchar(10)
as
begin
	delete from ChiTietHoaDon where MaHD = @MaHD and MaSach = @MaSach
end

Go
CREATE PROCEDURE ThemNhaXuatBan
	@MaNXB nchar(10),
	@TenNXB nvarchar(50),
	@DiaChiNXB nvarchar(100),
	@LienHe nvarchar(15)
	
AS
BEGIN
	
	BEGIN TRANSACTION
	BEGIN TRY
		-- Kiểm tra xem đã tồn tại hay chưa
		IF NOT EXISTS (SELECT * FROM NhaXuatBan WHERE MaNXB =@MaNXB)
		BEGIN
			-- Nếu chưa tồn tại, thêm mới nha xuat ban
			INSERT INTO NhaXuatBan(MaNXB, TenNXB, DiaChiNXB,LienHe)
			VALUES (@MaNXB, @TenNXB,@DiaChiNXB, @LienHe)
		END
		COMMIT TRAN

	END TRY
	BEGIN CATCH
		ROLLBACK
		DECLARE @err NVARCHAR(MAX)
		SELECT @err = ERROR_MESSAGE()
		RAISERROR(@err, 16, 1)
	END CATCH
END

-- proc sửa NhaXuatBan
go
CREATE PROCEDURE SuaNhaXuatBan
	@MaNXB nchar(10),
	@TenNXB nvarchar(50),
	@DiaChiNXB nvarchar(100),
	@LienHe nvarchar(15)
	
AS
BEGIN
	BEGIN TRY
		UPDATE dbo.NhaXuatBan SET MaNXB = @MaNXB, TenNXB = @TenNXB, DiaChiNXB= @DiaChiNXB, LienHe = @LienHe
		WHERE MaNXB = @MaNXB
	END TRY
	BEGIN CATCH
		DECLARE @err NVARCHAR(MAX)
		SELECT @err = ERROR_MESSAGE()
		RAISERROR(@err, 16, 1)
	END CATCH
END
-- Tạo Proc CRUD tác giả
--a/ Thêm tác giả
GO
CREATE PROCEDURE ThemTacGia
    @MaTG NCHAR(10),
    @MaNXB NCHAR(10),
    @TenTG NVARCHAR(50),
    @LienHe NCHAR(15)
AS
BEGIN
    INSERT INTO TacGia (MaTG, MaNXB, TenTG, LienHe)
    VALUES (@MaTG, @MaNXB, @TenTG, @LienHe)
END

GO
--b/ Cập nhật thông tin tác giả
CREATE PROCEDURE CapNhatTacGia
    @MaTG NCHAR(10),
    @MaNXB NCHAR(10),
    @TenTG NVARCHAR(50),
    @LienHe NCHAR(15)
AS
BEGIN
    UPDATE TacGia
    SET MaNXB = @MaNXB, TenTG = @TenTG, LienHe = @LienHe
    WHERE MaTG = @MaTG
END

GO
--c/ Xóa tác giả
CREATE PROCEDURE XoaTacGia
    @MaTG NCHAR(10)
AS
BEGIN
    DELETE FROM TacGia
    WHERE MaTG = @MaTG
END
GO