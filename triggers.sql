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
    IF EXISTS (SELECT * FROM inserted WHERE TRIM(TenTG) = '' OR TRIM(MaTG) = '')
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

--17. Trigger cập nhật MaNXB bảng Sach khi sửa bên bảng Tacgia
CREATE TRIGGER trg_UpdateMaNXB
ON TacGia
AFTER UPDATE
AS
BEGIN
    UPDATE Sach
    SET MaNXB = i.MaNXB
    FROM Sach s
    INNER JOIN inserted i ON s.MaTG = i.MaTG
    WHERE i.MaNXB IS NOT NULL;
END;
go
