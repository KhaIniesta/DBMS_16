CREATE DATABASE QLNhaSach
GO
USE QLNhaSach
GO

CREATE TABLE NhaXuatBan (
    MaNXB NCHAR(10) PRIMARY KEY,
    TenNXB NVARCHAR(50) NOT NULL,
    DiaChiNXB NVARCHAR(100),
    LienHe NVARCHAR(50) NOT NULL
)
go
CREATE TABLE TacGia(
    MaTG NCHAR(10) PRIMARY KEY, 
    MaNXB NCHAR(10) REFERENCES NhaXuatBan(MaNXB) ON DELETE SET NULL, 
    TenTG NVARCHAR(50) NOT NULL, 
    LienHe NVARCHAR(50)
)
go
CREATE TABLE Sach(
    MaSach NCHAR(10) PRIMARY KEY, 
    MaTG NCHAR(10) REFERENCES TacGia(MaTG) ON DELETE SET NULL, 
    MaNXB NCHAR(10) REFERENCES NhaXuatBan(MaNXB) ON DELETE SET NULL, 
    TenSach NVARCHAR(100) NOT NULL, 
    SoLuongSach INT NOT NULL CHECK(SoLuongSach >= 0), 
    Gia MONEY NOT NULL CHECK(Gia > 0), 
    TheLoai NVARCHAR(50) NOT NULL,
    Anh IMAGE
)
go
CREATE TABLE PhieuNhap(
    MaPhieuNhap NCHAR(10) PRIMARY KEY, 
    MaNXB NCHAR(10) REFERENCES NhaXuatBan(MaNXB) ON DELETE SET NULL, 
    NgayNhap DATETIME NOT NULL 
)
go
CREATE TABLE ChiTietPhieuNhap(
    MaPhieuNhap NCHAR(10) REFERENCES PhieuNhap(MaPhieuNhap), 
    MaSach NCHAR(10) REFERENCES Sach(MaSach), 
    SoLuongNhap INT NOT NULL CHECK (SoLuongNhap > 0),
    PRIMARY KEY (MaPhieuNhap, MaSach)
)
go
CREATE TABLE HoaDon(
    MaHD NCHAR(15) PRIMARY KEY, 
    TongHD MONEY CHECK( TongHD >= 0) DEFAULT 0, 
    NgayInHD DATETIME NOT NULL
)
go
CREATE TABLE ChiTietHoaDon(
    MaHD NCHAR(15) REFERENCES HoaDon(MaHD), 
    MaSach NCHAR(10) REFERENCES Sach(MaSach), 
    SoLuongBan INT CHECK (SoLuongBan > 0), 
    Gia MONEY NOT NULL DEFAULT 0 CHECK(Gia >= 0),
    PRIMARY KEY (MaHD, MaSach)
)
GO

-- PHẦN TẠO CÁC TRIGGER:==========================================================================
use QLNhaSach
go 
--1. trigger phat hien chua dien du thong tin Nha xuat ban
CREATE TRIGGER TG_InsertNhaXuatBan ON NhaXuatBan
FOR INSERT, UPDATE
AS
BEGIN
-- check MaKH
	IF EXISTS (SELECT * FROM inserted WHERE TRIM(MaNXB) = ' ')
	BEGIN
		RAISERROR('Mã NXB không được để trống', 16, 1)
		ROLLBACK 
		RETURN
	END
	-- check ten NXB
	IF EXISTS (SELECT * FROM inserted WHERE TRIM(TenNXB) = ' ')
	BEGIN
		RAISERROR('Tên NXB không được để trống', 16, 1)
		ROLLBACK 
		RETURN
	END
	-- check SDT
	IF EXISTS (SELECT * FROM inserted WHERE TRIM(LienHe) = ' ')
	BEGIN
		RAISERROR('Liên hệ không được để trống', 16, 1)
		ROLLBACK 
		RETURN
	END
END
GO

-- 2. Trigger bắt lỗi nhập thiếu thông tin khi thêm, sửa, xoá cho bảng TacGia
CREATE TRIGGER TG_Trigger_TacGia_InsUpdDel
ON TacGia
AFTER INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra lỗi nhập thiếu thông tin khi thêm hoặc sửa
    IF EXISTS (SELECT * FROM inserted WHERE TRIM(TenTG) = '' OR TRIM(LienHe) = '')
    BEGIN
        RAISERROR('Thông tin không đủ khi thêm, sửa', 16, 1)
        ROLLBACK
        RETURN
    END
END
GO

-- 3. Trigger 
CREATE TRIGGER TG_Trigger_TacGia_Change
ON TacGia
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Cập nhật các bản ghi trong Sach khi TacGia được cập nhật
    IF EXISTS (SELECT * FROM inserted INNER JOIN Sach ON inserted.MaTG = Sach.MaTG)
    BEGIN
        UPDATE Sach
        SET MaTG = inserted.MaTG
        FROM Sach
        INNER JOIN inserted ON Sach.MaTG = inserted.MaTG;
    END;
END;
GO

--4. Trigger kiểm tra sách đã tồn tại trước đó
CREATE TRIGGER TG_KiemTraTrungSach
ON Sach
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @InsertedMaSach NCHAR(10);
	SELECT @InsertedMaSach = MaSach
    FROM INSERTED;
   
    IF EXISTS (SELECT 1 FROM Sach WHERE MaSach = @InsertedMaSach)
    BEGIN
        RAISERROR ('Sách đã có trước đó!', 16, 1);
    END
	ELSE 
	BEGIN
		INSERT INTO Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai)
		SELECT MaSach, MaTG, MaNXB, TenSach, SoLuongSach, Gia, TheLoai
		FROM INSERTED
	END
END
GO

--5. Nếu Sách có xuất hiện bên chi tiết phiếu nhập hoặc có xuất hiện bên CTHD thì không cho xóa
IF OBJECT_ID ('TG_Sach_Delete', 'TR') IS NOT NULL 
  DROP TRIGGER TG_Sach_Delete; 
GO
CREATE TRIGGER TG_Sach_Delete
ON Sach
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @DeletedMaSach NCHAR(10);

    -- Lấy các MaSach bị xóa
    SELECT @DeletedMaSach = MaSach
    FROM DELETED;

    -- Kiểm tra xem có MaSach nào được tham chiếu từ ChiTietPhieuNhap không
    IF EXISTS (SELECT 1 FROM ChiTietPhieuNhap WHERE MaSach = @DeletedMaSach)
    BEGIN
        RAISERROR ('Sách đã xuất hiện bên chi tiết phiếu nhập, không thể xóa!', 16, 1);
    END
    ELSE IF EXISTS (SELECT 1 FROM ChiTietHoaDon WHERE MaSach = @DeletedMaSach)
    BEGIN
        RAISERROR ('Sách đã xuất hiện bên chi tiết hóa đơn, không thể xóa!', 16, 1);
    END
    ELSE
    BEGIN
        -- Xóa bản ghi từ bảng Sách
        DELETE FROM Sach WHERE MaSach = @DeletedMaSach;
    END
END;
GO

--6. Trigger kiểm tra phiếu nhập tồn tại trước đó
CREATE TRIGGER TG_KiemTraTrungPhieuNhap
ON PhieuNhap
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @InsertedMaPhieuNhap NCHAR(10);
	SELECT @InsertedMaPhieuNhap = MaPhieuNhap
    FROM INSERTED;

    IF EXISTS (SELECT 1 FROM PhieuNhap WHERE MaPhieuNhap = @InsertedMaPhieuNhap)
    BEGIN
        RAISERROR ('Phiếu nhập đã có trước đó!', 16, 1);
    END
	ELSE 
	BEGIN
		INSERT INTO PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap)
		SELECT MaPhieuNhap,MaNXB,NgayNhap
		FROM INSERTED
	END
END
GO

-- 7. Nếu phiếu nhập có xuất hiện bên chi tiết phiếu nhập thì không cho xóa
IF OBJECT_ID ('TG_PhieuNhap_Delete', 'TR') IS NOT NULL 
  DROP TRIGGER TG_PhieuNhap_Delete; 
GO
CREATE TRIGGER TG_PhieuNhap_Delete
ON PhieuNhap
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @DeletedMaPhieuNhap NCHAR(10);

    -- Lấy các MaPhieuNhap bị xóa
    SELECT @DeletedMaPhieuNhap = MaPhieuNhap
    FROM DELETED;

    -- Kiểm tra xem có MaPhieuNhap nào được tham chiếu từ ChiTietPhieuNhap không
    IF EXISTS (SELECT 1 FROM ChiTietPhieuNhap WHERE MaPhieuNhap = @DeletedMaPhieuNhap)
    BEGIN
        RAISERROR ('Phiếu nhập đã xuất hiện bên chi tiết phiếu nhập, chọn Yes sẽ xóa phiếu nhập hiện tại và chi tiết phiếu nhập!', 16, 1);
    END
    ELSE
    BEGIN
        -- Xóa bản ghi từ bảng PhieuNhap
        DELETE FROM PhieuNhap WHERE MaPhieuNhap = @DeletedMaPhieuNhap;
    END
END;
GO

-- 8. Kiểm tra thông tin sách lúc nhập kho có bị trùng không, nếu mã sách đã tồn tại và mã nxb của sách đúng với mã nxb ở phiếu nhập tương ứng thì tăng số lượng sách trong bảng sách
IF OBJECT_ID ('Trigger_TangSoLuongSach', 'TR') IS NOT NULL 
  DROP TRIGGER TG_Trigger_TangSoLuongSach; 
GO
CREATE TRIGGER TG_Trigger_TangSoLuongSach
ON ChiTietPhieuNhap
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @InsertedMaPhieuNhap NCHAR(10)
	DECLARE @InsertedMaSach NCHAR(10)

	SELECT @InsertedMaPhieuNhap = MaPhieuNhap, @InsertedMaSach = MaSach
    FROM INSERTED

    IF EXISTS (SELECT 1 FROM ChiTietPhieuNhap WHERE MaPhieuNhap = @InsertedMaPhieuNhap AND MaSach = @InsertedMaSach)
    BEGIN
        RAISERROR ('Chi tiết phiếu nhập đã có trước đó!', 16, 1);
    END
	ELSE 
	BEGIN
		-- Kiểm tra và cập nhật số lượng sách
		DECLARE @MaPhieuNhap NCHAR(10)
		DECLARE @MaSach NCHAR(10)
    
		SELECT @MaPhieuNhap = i.MaPhieuNhap, @MaSach = i.MaSach
		FROM inserted i

		IF EXISTS (
			SELECT 1
			FROM Sach s
			INNER JOIN PhieuNhap pn ON s.MaNXB = pn.MaNXB
			WHERE s.MaSach = @MaSach
			AND pn.MaPhieuNhap = @MaPhieuNhap
		)
		BEGIN
			-- Tăng số lượng sách
			UPDATE Sach
			SET SoLuongSach = SoLuongSach + (SELECT SoLuongNhap FROM inserted WHERE MaPhieuNhap = @MaPhieuNhap AND MaSach = @MaSach)
			WHERE MaSach = @MaSach
			RAISERROR('Đã tăng số lượng sách', 16, 1)
			-- Chèn dữ liệu vào bảng ChiTietPhieuNhap
			INSERT INTO ChiTietPhieuNhap (MaPhieuNhap, MaSach, SoLuongNhap)
			SELECT MaPhieuNhap, MaSach, SoLuongNhap FROM inserted
		END
		ELSE
		BEGIN
			RAISERROR('Sách chưa tồn tại', 16, 1)
		END
	END
END
GO

-- 9. Kiểm tra số lượng từng loại sách trong kho có đủ để bán không
CREATE TRIGGER TG_KTSachTrongKho
ON ChiTietHoaDon
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @SoLuongSach INT, @SoLuongBan INT
	
	SELECT @SoLuongSach = Sach.SoLuongSach, @SoLuongBan = inserted.SoLuongBan
	FROM Sach join inserted ON Sach.MaSach = inserted.MaSach

	IF (@SoLuongSach<@SoLuongBan)
		BEGIN
			RAISERROR('Số lượng sách trong kho không đủ để bán ', 16, 1);
			Rollback;
		END;
END;

--. Trigger cap nhat so luong sach sau khi dat hang - xuat hoa don 

-- 10. Sau khi đặt hàng - xuất hóa đơn
--Cong thuc tinh sl con lai: soluongsach = soluongsach - soluongban + soluonghuy
go
create trigger TG_SoLuongSauDatHang on ChiTietHoaDon
after insert as
begin
	update Sach
	set SoLuongSach = SoLuongSach - (select SoLuongBan from inserted where MaSach = Sach.MaSach)
	from Sach join inserted on Sach.MaSach = inserted.MaSach
end;
go

-- 11. Sau khi xóa hoặc hủy đơn hàng - xóa khỏi danh sách hóa đơn
create trigger TG_SoLuongSauXoaDatHang on ChiTietHoaDon
for delete as
begin
	update Sach
	set SoLuongSach = SoLuongSach + (select SoLuongBan from deleted where MaSach = Sach.MaSach)
	from Sach join deleted on Sach.MaSach = deleted.MaSach
end;
go

-- 12. Sau khi cập nhật lại số lượng sách trong hóa đơn
create trigger TG_SoLuongSauCapNhat on ChiTietHoaDon
after update as
begin
	update Sach
	set SoLuongSach = SoLuongSach - (select SoLuongBan from inserted where MaSach = Sach.MaSach)
	+ (select SoLuongBan from deleted where MaSach = Sach.MaSach)
	from Sach join deleted on Sach.MaSach = deleted.MaSach
end;
go

--  13. Tính giá của từng mặt hàng trong chi tiết hóa đơn = Giá(bảng sách) * số lượng(chi tiết hóa dơn)
IF OBJECT_ID ('Trigger_TinhGiaChiTietHoaDon', 'TR') IS NOT NULL 
  DROP TRIGGER TG_Trigger_TinhGiaChiTietHoaDon; 
GO

CREATE TRIGGER TG_Trigger_TinhGiaChiTietHoaDon
ON ChiTietHoaDon
AFTER INSERT, UPDATE
AS
BEGIN
    -- Cập nhật giá (Gia) trong ChiTietHoaDon
    UPDATE ChiTietHoaDon
    SET Gia = Sach.Gia * inserted.SoLuongBan
    FROM ChiTietHoaDon
    INNER JOIN inserted ON ChiTietHoaDon.MaHD = inserted.MaHD AND ChiTietHoaDon.MaSach = inserted.MaSach
    INNER JOIN Sach ON ChiTietHoaDon.MaSach = Sach.MaSach;
END
GO

---- Trigger cập nhật tổng hóa đơn trong bảng hóa đơn 
-- 14. Cập nhật lại tổng hóa đơn sau khi thêm sp (thêm giá) vào chi tiết hóa đơn
create trigger TG_TinhTongHoaDonKhiThem on ChiTietHoaDon
after update as
begin
	update HoaDon
	set TongHD = TongHD + (select sum(Gia) from inserted where MaHD = HoaDon.MaHD) - (select sum(Gia) from deleted where MaHD = HoaDon.MaHD)
	from HoaDon join deleted on HoaDon.MaHD = deleted.MaHD
end;
go
-- 15. Cập nhật lại tổng hóa đơn sau khi xóa sp ra khỏi chi tiết hóa đơn
create trigger TG_TinhTongHoaDonKhiXoa on ChiTietHoaDon
after delete as
begin
	update HoaDon
	set TongHD = TongHD - (select sum(Gia) from deleted where MaHD = HoaDon.MaHD)
	from HoaDon join deleted on HoaDon.MaHD = deleted.MaHD
end;
go

--16. Trigger check trùng mã sách khi nhập vào chi tiết hóa đơn
create trigger TG_CheckMaSachTrungCTHD
on ChiTietHoaDon
instead of insert
as
begin
	declare @mahd nchar(15) set @mahd = (select MaHD from inserted) 
	declare @masach nchar(10) set @masach = (select MaSach from inserted)
	declare @soluong int set @soluong = (select SoLuongBan from inserted) 

	if exists (select MaSach from chitiethoadon cthd where MaSach = @masach and MaHD = @mahd)
	begin
		raiserror ('Sách đã có trong chi tiết hóa đơn, vui lòng chọn lại!', 16, 1)
		rollback
	end
	else
	begin 
		insert into ChiTietHoaDon(MaHD, MaSach, SoLuongBan) values (@mahd, @masach, @soluong)
	end
end
go

--16. Trigger kiểm tra MaTG có tồn tại trước đó hay không
CREATE TRIGGER TG_KiemTraMaTacGia
ON TacGia
INSTEAD OF INSERT
AS
BEGIN	
		-- Kiểm tra xem MaTG đã tồn tại hay chưa
    IF NOT EXISTS (SELECT * FROM TacGia TG WHERE TG.MaTG IN (SELECT MaTG FROM inserted))
    BEGIN
        -- Thêm dữ liệu vào bảng TacGia nếu MaTG không tồn tại
        INSERT INTO TacGia (MaTG, MaNXB, TenTG, LienHe)
        SELECT MaTG, MaNXB, TenTG, LienHe
        FROM inserted;
    END
    ELSE
    BEGIN
        
        RAISERROR('MaTG đã tồn tại!', 16, 1);
    END
END;
go

-- PHẦN STORED PROCEDURE =================================================================================
use QLNhaSach
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
		MaNXB = @MaNXB, 
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
    WHERE MaPhieuNhap = @MaPhieuNhap;
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
	@MaHD nchar(15)
as
begin
	update HoaDon set NgayInHD = GETDATE() where MaHD = @MaHD
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

go
-- Tìm kiếm mã hóa đơn
create procedure Proc_TimKiemMaHD
as
begin
    select distinct MaHD, TongHD from HoaDon order by MaHD
end
go

-- Tìm kiếm mã tên sách
create procedure Proc_TimKiemTenSach
as
begin
    select distinct MaSach, TenSach from Sach order by TenSach
end
go


-- 6. Nhà xuất bản:
-- Thêm nhà xuất bản
Go
CREATE PROCEDURE Proc_ThemNhaXuatBan
	@MaNXB nchar(10),
	@TenNXB nvarchar(50),
	@DiaChiNXB nvarchar(100),
	@LienHe nvarchar(50)
	
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
		ELSE 
		BEGIN
			RAISERROR('Mã nhà xuất bản này đã tồn tại', 16, 1)
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
CREATE PROCEDURE Proc_SuaNhaXuatBan
	@MaNXB nchar(10),
	@TenNXB nvarchar(50),
	@DiaChiNXB nvarchar(100),
	@LienHe nvarchar(50)
	
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

GO


CREATE PROCEDURE Proc_XoaNhaXuatBan
    @MaNXB NCHAR(10)
AS
BEGIN
    DELETE FROM NhaXuatBan
    WHERE MaNXB = @MaNXB
END
GO
-- 7. Tạo Proc CRUD tác giả
--a/ Thêm tác giả
GO
CREATE PROCEDURE ThemTacGia
    @MaTG NCHAR(10),
    @MaNXB NCHAR(10),
    @TenTG NVARCHAR(50),
    @LienHe NVARCHAR(50)
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
    @LienHe NVARCHAR(15)
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

-- Proc xuất hóa đơn ra report
create procedure Proc_XuatHoaDon
	@MaHD nchar(15)
as
begin
	select hd.MaHD, s.MaSach, s.TenSach, tg.TenTG, nxb.TenNXB, s.TheLoai, cthd.SoLuongBan, cthd.Gia, hd.TongHD, hd.NgayInHD 
	from ChiTietHoaDon cthd join HoaDon hd on cthd.MaHD = hd.MaHD join Sach s on s.MaSach = cthd.MaSach 
		join TacGia tg on s.MaTG = tg.MaTG join NhaXuatBan nxb on s.MaNXB = nxb.MaNXB
	where hd.MaHD = @MaHD
end
go

GO
CREATE PROCEDURE Proc_XoaChiTietPhieuNhapTheoMaPhieuNhap
	@MaPhieuNhap NCHAR(10)
AS
BEGIN
	DELETE ChiTietPhieuNhap 
	WHERE MaPhieuNhap = @MaPhieuNhap 
END
GO
-- ==================== PHẦN CÁC FUNCTION============================
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
GO

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
	from Sach 
	join TacGia on Sach.MaTG = TacGia.MaTG
	join NhaXuatBan on Sach.MaNXB = NhaXuatBan.MaNXB
	order by Sach.TenSach
go

-- PHẦN INSERT DATA:==========================================================================
use QLNhaSach
-- Insert Data into NhaXuatBan:
insert into NhaXuatBan(MaNXB,TenNXB,DiaChiNXB,LienHe) values ('NXB_KD',N'NXB Kim Đồng',N'248 Cống Quỳnh, P. Phạm Ngũ Lão, Q.1 TP. Hồ Chí Minh','info@nxbkimdong.com.vn')											
insert into NhaXuatBan(MaNXB,TenNXB,DiaChiNXB,LienHe) values ('NXB_T',N'NXB Trẻ',N'161B Lý Chính Thắng, phường Võ Thị Sáu, Quận 3, TP. Hồ Chí Minh','hopthubandoc@nxbtre.com.vn ')											
insert into NhaXuatBan(MaNXB,TenNXB,DiaChiNXB,LienHe) values ('NXB_PNVN',N'NXB Phụ nữ VN',N'39 Hàng Chuối, Quận Hai Bà Trưng, Hà Nội ','truyenthongvaprnxbpn@gmail.com')											
insert into NhaXuatBan(MaNXB,TenNXB,DiaChiNXB,LienHe) values ('NXB_NN',N'Nhã Nam',N'59 Đỗ Quang, Cầu Giấy, Hà Nội','bookstore@nhanam.vn')											
insert into NhaXuatBan(MaNXB,TenNXB,DiaChiNXB,LienHe) values ('NXB_DTB',N'Đinh Tị Books',N'Trụ sở Nhà NV22, Khu 12, Ngõ 13 Lĩnh Nam, P. Mai Động, Q. Hoàng Mai, Hà Nội','contacts@dinhtibooks.vn')											
insert into NhaXuatBan(MaNXB,TenNXB,DiaChiNXB,LienHe) values ('NXB_VH',N'NXB Văn Học',N'18 Nguyễn Trường Tộ, Ba Đình, Hà Nội','0904907492')											
insert into NhaXuatBan(MaNXB,TenNXB,DiaChiNXB,LienHe) values ('NXB_TH',N'NXB Tổng hợp Tp.HCM',N'62 Nguyễn Thị Minh Khai, Phường Đa Kao, Quận 1, TP.HCM','nstonghop@gmail.com')											
insert into NhaXuatBan(MaNXB,TenNXB,DiaChiNXB,LienHe) values ('NXB_DT',N'NXB Dân Trí',N'Số 9, ngõ 26, phố Hoàng Cầu, phường Ô Chợ Dừa, quận Đống Đa, Hà Nội','nxbdantri@gmail.com')											
insert into NhaXuatBan(MaNXB,TenNXB,DiaChiNXB,LienHe) values ('NXB_TG',N'NXB Thế Giới',N'46 Trần Hưng Đạo Str., Hà Nội, Việt Nam','thegioi@hn.vnn.vn')											

-- Insert Data into TacGia:
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_VT','NXB_TH',N'Vãn Tình','902201833')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_KG','NXB_TG',N' Katrina Goldsaito ','2587024666')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_ACD','NXB_VH',N'Arthur Conan Doyle','5274893230')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_CM','NXB_TG',N'Cao Minh','397952541')	--conflicted with the FOREIGN KEY constraint "FK__TacGia__MaNXB__267ABA7A". The conflict occurred in database "QLNhaSach", table "dbo.NhaXuatBan", column 'MaNXB'.									
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_TH','NXB_NN',N'Thomas Herris','2372324538')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_NNA','NXB_T',N'Nguyễn Nhật Ánh','987428432')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_SH','NXB_T',N'Stephen Hawking','5189176417')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_NNT','NXB_T',N'Nguyễn Ngọc Thuần','932780176')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_TX','NXB_T',N'Trịnh Xuân','372142564')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_THOAI','NXB_KD',N'Tô Hoài','984890830')	--The duplicate key value is (TG_TH     ).									
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_JL','NXB_KD',N'Julie Lardon','3627152638')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_MA','NXB_KD',N'Mitch Albom','7152633351')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_VTP','NXB_KD',N'Vũ Trọng Phụng','373251252')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_LT','NXB_TG',N'Lê Trinh','392526143')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_THG','NXB_DTB',N'Thanh Hường','862511929')	--The duplicate key value is (TG_TH     ).									
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_TV','NXB_DTB',N'Thất Vi','331362536')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_LCY','NXB_TG',N'Lim Chong Yah','8725169211')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_AG','NXB_VH',N'Antoine Galland','5726253321')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_CG','NXB_PNVN',N'Camilla Grebe','3172225163')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_NQM','NXB_PNVN',N'Nguyễn Quang Minh','9725136621')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_KL','NXB_DT',N'Kent Lineback','5268156222')		

-- Insert Data into Sach:
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('1','TG_MA','NXB_KD',N'Những ngày thứ ba với thầy Morrie','65','52000',N'Văn học nước ngoài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('2','TG_JL','NXB_KD',N'Thế giới tương lai - Nuôi nhân loại','50','60200',N'Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('3','TG_TH','NXB_KD',N'Dế Mèn phiêu lưu ký','125','35000',N'Văn học Việt Nam')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('4','TG_VTP','NXB_KD',N'Số đỏ','131','42000',N'Văn học Việt Nam')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('5','TG_NNA','NXB_T',N'Còn chút gì để nhớ','60','33000',N'Truyện dài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('6','TG_TX','NXB_T',N'Những con đường của ánh sáng','160','80000',N'Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('7','TG_NNT','NXB_T',N'Vừa nhắm mắt vừa mở cửa sổ','125','45000',N'Truyện dài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('8','TG_SH','NXB_T',N'Lược sử thời gian','90','115000',N'Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('9','TG_SH','NXB_T',N'Vũ trụ trong vỏ hạt dẻ','92','110000',N'Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('10','TG_CG','NXB_PNVN',N'Tiếng thét dưới băng','80','32000',N'Văn học nước ngoài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('11','TG_NQM','NXB_PNVN',N'Bí quyết để thành công ở trường đại học','50','50000',N'Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('12','TG_TH','NXB_NN',N'Sự im lặng của bầy cừu','135','92000',N'Trinh thám')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('13','TG_TH','NXB_NN',N'Rồng đỏ','68','114750',N'Tâm lý')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('14','TG_NNA','NXB_DTB',N'Tôi thấy hoa vàng trên cỏ xanh','160','125500',N'Truyện thiếu nhi')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('15','TG_TH','NXB_DTB',N'Bách khoa tri thức dành cho trẻ em','75','60000',N'Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('16','TG_TV','NXB_DTB',N'Gió nam thầm thì','110','86000',N'Truyện dài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('17','TG_AG','NXB_VH',N'Nghìn lẻ một đêm','100','204000',N'Văn học nước ngoài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('18','TG_ACD','NXB_VH',N'Những cuộc phiêu lưu của Sherlock Holmes','72','63200',N'Trinh thám')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('20','TG_VT','NXB_TH',N'Không tự khinh bỉ, không tự phí hoài','47','109000',N'Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('21','TG_VT','NXB_TH',N'Bạn đắt giá bao nhiêu','64','96000',N'Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('22','TG_VT','NXB_TH',N'Không sợ chậm, chỉ sợ dừng','81','94000',N'Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('23','TG_VT','NXB_TH',N'Lấy tình thâm để đổi đầu bạc','98','129000',N'Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('24','TG_KL','NXB_DT',N'Thiên tài tập thể','200','89600',N'Tâm lý')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('25','TG_LCY','NXB_TG',N'Đông Nam á - chặng đường dài phía trước','135','76000',N'Văn học nước ngoài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('26','TG_LT','NXB_TG',N'To be a Woman Doctor in Vietnam','60','90000',N'Tâm lý')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('27','TG_KG','NXB_TG',N'Âm thanh của sự im lặng','27','98000',N'Kinh dị')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('28','TG_CM','NXB_TG',N'Thiên tài bên trái, kẻ điên bên phải','46','123000',N'Tâm lý')											

-- Insert Data into PhieuNhap:
insert into PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap) values ('PN01','NXB_KD','2023-08-05 00:00:00')					
insert into PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap) values ('PN02','NXB_T','2023-08-05 00:00:00')					
insert into PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap) values ('PN03','NXB_PNVN','2023-08-10 00:00:00')					
insert into PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap) values ('PN04','NXB_NN','2023-08-10 00:00:00')					
insert into PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap) values ('PN05','NXB_DTB','2023-08-10 00:00:00')					
insert into PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap) values ('PN06','NXB_VH','2023-08-20 00:00:00')					
insert into PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap) values ('PN07','NXB_TH','2023-08-20 00:00:00')					
insert into PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap) values ('PN08','NXB_DT','2023-08-20 00:00:00')					
insert into PhieuNhap(MaPhieuNhap,MaNXB,NgayNhap) values ('PN09','NXB_TG','2023-08-20 00:00:00')

-- Insert Data into ChiTietPhieuNhap:
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN01','1','20')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN01','2','30')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN01','3','70')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN01','4','80')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN02','5','20')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN02','6','100')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN02','7','90')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN02','8','40')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN02','9','45')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN03','10','30')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN03','11','15')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN04','12','75')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN04','13','30')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN05','14','125')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN05','15','40')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN05','16','50')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN06','17','55')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN06','18','30')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN07','20','20')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN07','21','20')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN07','22','45')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN07','23','35')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN08','24','145')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN09','25','80')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN09','26','35')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN09','27','15')					
insert into ChiTietPhieuNhap(MaPhieuNhap,MaSach,SoLuongNhap) values ('PN09','28','20')					

-- Insert Data into HoaDon:
insert into HoaDon(MaHD,NgayInHD) values ('HD01','2023-09-02 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD02','2023-09-02 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD03','2023-09-02 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD04','2023-09-03 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD05','2023-09-03 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD06','2023-09-03 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD07','2023-09-04 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD08','2023-09-04 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD09','2023-09-04 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD10','2023-09-05 00:00:00')						
insert into HoaDon(MaHD,NgayInHD) values ('HD11','2023-09-05 00:00:00')						

-- Insert Data into ChiTietHoaDon:
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD01','1','15')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD01','2','20')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD01','4','30')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD01','3','40')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD02','5','20')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD02','6','80')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD02','7','35')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD02','8','40')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD02','9','30')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD03','10','30')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD03','11','10')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD04','12','20')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD04','13','30')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD05','14','85')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD05','15','40')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD05','16','40')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD06','17','50')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD06','18','30')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD07','20','10')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD07','21','5')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD08','22','30')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD09','23','35')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD09','24','90')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD10','25','30')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD10','26','25')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD11','27','15')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan) values ('HD11','28','15')					
GO 

USE QLNhaSach
GO
--================ PHÂN QUYỀN ================
-- THIẾT LẬP CÁC ROLE:
-- 2. Tạo role cho NhanVienThuNgan: thêm, sửa, xóa Hóa đơn, CT hóa đơn--------------------------------
CREATE ROLE NhanVienThuNgan
--Gán các quyền trên table cho role admin_nhasach
GRANT SELECT,INSERT,UPDATE, DELETE ON HoaDon TO NhanVienThuNgan
GRANT SELECT,INSERT,UPDATE, DELETE ON ChiTietHoaDon TO NhanVienThuNgan
GRANT SELECT ON Sach TO NhanVienThuNgan
GRANT SELECT ON TacGia TO NhanVienThuNgan
GRANT SELECT ON NhaXuatBan TO NhanVienThuNgan
GO
--. Gán quyền thực thi trên các procedure, function cho role NhanVienThuNgan
GRANT EXECUTE ON Proc_ThemMaHoaDon TO NhanVienThuNgan
GRANT SELECT ON V_HienChiTietSach TO NhanVienThuNgan
GRANT EXECUTE ON Proc_HienCTHDTheoMaHD TO NhanVienThuNgan
GRANT EXECUTE ON Proc_TimKiemTheoMaHD TO NhanVienThuNgan
GRANT EXECUTE ON Proc_TimKiemMaHD TO NhanVienThuNgan
GRANT EXECUTE ON Proc_TimKiemTenSach TO NhanVienThuNgan
GRANT EXECUTE ON Proc_ThemSachCTHD TO NhanVienThuNgan
GRANT EXECUTE ON Proc_CapNhatSachCTHD TO NhanVienThuNgan
GRANT EXECUTE ON Proc_XoaSachCTHD TO NhanVienThuNgan
GRANT EXECUTE ON Proc_XoaHoaDon TO NhanVienThuNgan
GRANT EXECUTE ON Proc_HienCTHDTheoTenSach TO NhanVienThuNgan
GRANT EXECUTE ON Proc_CapNhatHoaDon TO NhanVienThuNgan
GRANT EXECUTE ON Proc_XuatHoaDon TO NhanVienThuNgan
GO

-- 3. Tạo role cho QuanLiKho: thêm, sửa, xóa Tác giả, Sách, Phiếu nhập, CT Phiếu nhập --------------------------------
CREATE ROLE QuanLiKho
--Gán các quyền trên table cho role QuanLiKho
GRANT SELECT,INSERT,UPDATE, DELETE ON TacGia TO QuanLiKho
GRANT SELECT,INSERT,UPDATE, DELETE ON Sach TO QuanLiKho
GRANT SELECT,INSERT,UPDATE, DELETE ON PhieuNhap TO QuanLiKho
GRANT SELECT,INSERT,UPDATE, DELETE ON ChiTietPhieuNhap TO QuanLiKho
go
--. Gán quyền thực thi trên các procedure, function, views cho role QuanLiKho
GRANT SELECT ON NhaXuatBan TO QuanLiKho
GRANT SELECT ON Func_LayBangSach TO QuanLiKho
GRANT EXECUTE ON Proc_XoaSach TO QuanLiKho
GRANT EXECUTE ON Proc_ThemSach TO QuanLiKho
GRANT EXECUTE ON Proc_SuaSach TO QuanLiKho
GRANT EXECUTE ON ThemTacGia TO QuanLiKho
GRANT EXECUTE ON CapNhatTacGia TO QuanLiKho
GRANT EXECUTE ON XoaTacGia TO QuanLiKho
GRANT SELECT ON TimKiemSachTheoTacGia TO QuanLiKho
GRANT SELECT ON Func_LayBangPhieuNhap TO QuanLiKho
GRANT EXECUTE ON Proc_XoaPhieuNhap TO QuanLiKho
GRANT EXECUTE ON Proc_XoaChiTietPhieuNhapTheoMaPhieuNhap TO QuanLiKho
GRANT EXECUTE ON Proc_ThemPhieuNhap TO QuanLiKho
GRANT EXECUTE ON Proc_SuaPhieuNhap TO QuanLiKho
GRANT SELECT ON V_ChiTietCacPhieuNhap TO QuanLiKho
GRANT EXECUTE ON Proc_XoaChiTietPhieuNhap TO QuanLiKho
GRANT EXECUTE ON Proc_ThemChiTietPhieuNhap  TO QuanLiKho
GRANT EXECUTE ON Proc_SuaChiTietPhieuNhap TO QuanLiKho
GO



--THIẾT LẬP LIÊN QUAN TaiKhoan--------------------
--1. Tạo bảng TaiKhoan trong cơ sở dữ liệu, hỗ trợ việc phân quyền
CREATE TABLE TaiKhoan(
	TenDangNhap varchar(50) PRIMARY KEY,
	MatKhau varchar(50),
	Cap int,
    TenNguoiDung NVARCHAR(50),
    Anh IMAGE,
    ChucVu NVARCHAR(50)
)
GO

--2. Proc tạo TaiKhoan
CREATE PROC Proc_ThemTaiKhoan
	@TenDangNhap varchar(50),
	@MatKhau varchar(50),
	@Cap int,
    @TenNguoiDung NVARCHAR(50) = '',
    @Anh IMAGE = NULL,
    @ChucVu NVARCHAR(50)= ''
AS
BEGIN 
	BEGIN 
		INSERT INTO TaiKhoan VALUES(@TenDangNhap, @MatKhau, @Cap, @TenNguoiDung, @Anh,  @ChucVu)
	END 
END
GO

-- Tự động tạo chức vụ khi insert tài khoản, sửa tài khoản
CREATE TRIGGER TG_TaiKhoan_TuDongTaoChucVu ON TaiKhoan 
AFTER INSERT, UPDATE
AS
BEGIN
    -- Cập nhật giá trị cột ChucVu dựa trên giá trị của cột Cap
    UPDATE TaiKhoan
    SET ChucVu = CASE 
                    WHEN I.Cap = 1 THEN 'Admin'
                    WHEN I.Cap = 2 THEN 'Nhân viên thu ngân'
                    ELSE 'Quản lí kho' -- Giữ nguyên giá trị nếu Cap không phải 1 hoặc 2
                END
    FROM TaiKhoan T
    INNER JOIN inserted I ON T.TenDangNhap = I.TenDangNhap;
END;
GO

--3. Trigger thêm TaiKhoan
CREATE TRIGGER TG_ThemTaiKhoan ON TaiKhoan
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @TenDangNhap nvarchar(30), @MatKhau nvarchar(10), @Cap int, @TenNguoiDung NVARCHAR(50), @Anh VARBINARY(MAX)=NULL
    DECLARE @sqlString nvarchar(2000)
    SELECT @TenDangNhap=i.TenDangNhap, @MatKhau=i.MatKhau, @Cap=i.Cap, @TenNguoiDung = i.TenNguoiDung, @Anh=i.Anh
    FROM inserted i

    IF EXISTS (SELECT 1 FROM TaiKhoan WHERE TenDangNhap = @TenDangNhap)
    BEGIN
        RAISERROR ('Tài khoản đã có trước đó!', 16, 1);
    END
    ELSE 
    BEGIN
        -- Insert account vào bảng Account
        INSERT INTO TaiKhoan(TenDangNhap, MatKhau, Cap, TenNguoiDung, Anh)
        SELECT TenDangNhap, MatKhau, Cap, TenNguoiDung, Anh
        FROM INSERTED
        --Tạo login
        SET @sqlString= 'CREATE LOGIN [' + @TenDangNhap + '] WITH PASSWORD = '''+ @MatKhau +''' '
        EXEC (@sqlString)
        --Tạo user
        SET @sqlString= 'CREATE USER [' + @TenDangNhap +'] FOR LOGIN ['+ @TenDangNhap + ']'
        EXEC (@sqlString)
        --Add thêm 1 user vào role
        IF @Cap = 1
            BEGIN
                SET @sqlString = 'ALTER SERVER ROLE sysadmin ADD MEMBER ['+ @TenDangNhap + ']';
            END

        ELSE IF @Cap = 2
            BEGIN
                SET @sqlString = 'ALTER ROLE NhanVienThuNgan ADD MEMBER ['+ @TenDangNhap + ']';
            END

        ELSE -- @Cap = 3
            BEGIN
                SET @sqlString = 'ALTER ROLE QuanLiKho ADD MEMBER [' + @TenDangNhap + ']';
            END
        EXEC (@sqlString)
    END
END
GO

--4. Proc xóa account
CREATE PROC Proc_XoaTaiKhoan
	@TenDangNhap varchar(50)
AS
DECLARE @sqlString NVARCHAR(2000)
DECLARE @sessionID int;
SELECT @sessionID = session_id
FROM sys.dm_exec_sessions
WHERE login_name = @TenDangNhap;
IF @sessionID IS NOT NULL
BEGIN
	-- Kiểm tra nếu là phiên làm việc hiện tại, không cho phép xóa
    IF @sessionID = @@SPID
    BEGIN
        RAISERROR ('Tài khoản muốn xóa đang là tài khoản hiện tại, không được xóa!', 16, 1);
        RETURN; -- Kết thúc thủ tục
    END
	ELSE
	BEGIN
        RAISERROR ('Tài khoản muốn xóa đang được đăng nhập!', 16, 1);
        RETURN; 
	END

END
BEGIN 
    BEGIN TRY
        --Xóa tài khoản trong table Account
        DELETE FROM TaiKhoan WHERE TenDangNhap = @TenDangNhap
        -- Xóa User trong database
        SET @sqlString = 'DROP USER ['+ @TenDangNhap + ']'
        EXEC (@sqlString)
        --Xóa login
        SET @sqlString = 'DROP LOGIN ['+ @TenDangNhap + ']'
        EXEC (@sqlString)
    END TRY
    BEGIN CATCH
        DECLARE @err nvarchar(MAX)
        SELECT @err = ERROR_MESSAGE()
        RAISERROR(@err,16,1)
        ROLLBACK
    END CATCH
END
GO

CREATE PROCEDURE Proc_CapNhatTaiKhoan
    @TenDangNhap VARCHAR(50),
    @MatKhauMoi VARCHAR(10),
    @CapMoi INT,
    @TenNguoiDung NVARCHAR(50) = '',
    @Anh IMAGE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MatKhauHienTai NCHAR(10);
    DECLARE @CapHienTai INT;

    BEGIN TRY
        -- Bắt đầu transaction
        BEGIN TRANSACTION;
        UPDATE TaiKhoan
        SET TenNguoiDung = @TenNguoiDung, Anh = @Anh
        WHERE TenDangNhap = @TenDangNhap
        -- Lấy mật khẩu và cấp hiện tại của người dùng
        SELECT @MatKhauHienTai = MatKhau, @CapHienTai = Cap
        FROM TaiKhoan
        WHERE TenDangNhap = @TenDangNhap;

        -- Kiểm tra xem có thay đổi mật khẩu hay không
        IF @MatKhauMoi IS NOT NULL AND @MatKhauMoi <> @MatKhauHienTai
        BEGIN
            -- Cập nhật mật khẩu trong bảng TaiKhoan
            UPDATE TaiKhoan
            SET MatKhau = @MatKhauMoi
            WHERE TenDangNhap = @TenDangNhap;

            -- Cập nhật mật khẩu cho tài khoản SQL Server
            EXEC('ALTER LOGIN [' + @TenDangNhap + '] WITH PASSWORD = ''' + @MatKhauMoi + '''')
        END

        -- Kiểm tra xem có thay đổi cấp hay không
        IF @CapMoi IS NOT NULL AND @CapMoi <> @CapHienTai
        BEGIN
            -- Cập nhật role cho tài khoản
            IF @CapMoi = 1
                EXEC sp_addsrvrolemember  @TenDangNhap, 'sysadmin'
            ELSE IF @CapMoi = 2
                EXEC sp_addrolemember'NhanVienThuNgan',  @TenDangNhap
            ELSE IF @CapMoi = 3
                EXEC sp_addrolemember'QuanLiKho',  @TenDangNhap

            -- Xóa role cho tài khoản
            IF @CapHienTai = 1
                EXEC sp_dropsrvrolemember @TenDangNhap, 'sysadmin'
            ELSE IF @CapHienTai = 2
                EXEC sp_droprolemember 'NhanVienThuNgan', @TenDangNhap
            ELSE IF @CapHienTai = 3
                EXEC sp_droprolemember 'QuanLiKho', @TenDangNhap

            -- Cập nhật cấp trong bảng TaiKhoan
            UPDATE TaiKhoan
            SET Cap = @CapMoi
            WHERE TenDangNhap = @TenDangNhap;
        END

        -- Commit transaction nếu không có lỗi
        COMMIT;
    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, hủy bỏ transaction
        RAISERROR ('Đã xảy ra lỗi trong quá trình cập nhật tài khoản!', 16, 1);
        ROLLBACK;
        -- Re-throw lỗi để nó được xử lý ở mức cao hơn
        THROW;
    END CATCH;
END;
GO

USE QLNhaSach
GO
EXEC Proc_ThemTaiKhoan
	@TenDangNhap = 'admin1',
	@MatKhau  = '111',
	@Cap = 1,
    @TenNguoiDung = 'Root'


