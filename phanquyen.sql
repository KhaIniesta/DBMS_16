--================ PHÂN QUYỀN ================
-- THIẾT LẬP CÁC ROLE:
-- 1. Tạo role cho admin: toàn quyền --------------------------------
CREATE ROLE admin_nhasach
--Gán các quyền trên table cho role admin_nhasach
GRANT SELECT,INSERT,UPDATE, DELETE ON NhaXuatBan TO admin_nhasach
GRANT SELECT,INSERT,UPDATE, DELETE ON TacGia TO admin_nhasach
GRANT SELECT,INSERT,UPDATE, DELETE ON Sach TO admin_nhasach
GRANT SELECT,INSERT,UPDATE, DELETE ON PhieuNhap TO admin_nhasach
GRANT SELECT,INSERT,UPDATE, DELETE ON ChiTietPhieuNhap TO admin_nhasach
GRANT SELECT,INSERT,UPDATE, DELETE ON HoaDon TO admin_nhasach
GRANT SELECT,INSERT,UPDATE, DELETE ON ChiTietHoaDon TO admin_nhasach
GO
--. Gán toàn bộ quyền thực thi trên các procedure, function cho role admin_nhasach
GRANT EXECUTE to admin_nhasach
GO

-- 2. Tạo role cho NhanVienThuNgan: thêm, sửa, xóa Hóa đơn, CT hóa đơn--------------------------------
CREATE ROLE NhanVienThuNgan
--Gán các quyền trên table cho role admin_nhasach
GRANT SELECT,INSERT,UPDATE, DELETE ON HoaDon TO NhanVienThuNgan
GRANT SELECT,INSERT,UPDATE, DELETE ON ChiTietHoaDon TO NhanVienThuNgan
GO
--. Gán quyền thực thi trên các procedure, function cho role NhanVienThuNgan
GRANT EXECUTE ON Proc_ThemSachCTHD to NhanVienThuNgan;
GRANT EXECUTE ON Proc_CapNhatSachCTHD to NhanVienThuNgan;
GRANT EXECUTE ON Proc_XoaSachCTHD to NhanVienThuNgan;
GRANT EXECUTE ON Proc_TimKiemTheoMaHD  to NhanVienThuNgan;
GRANT EXECUTE ON Proc_CapNhatHoaDon to NhanVienThuNgan;
GRANT EXECUTE ON Proc_XoaHoaDon to NhanVienThuNgan;
GRANT EXECUTE ON Proc_HienCTHDTheoMaHD to NhanVienThuNgan;
GRANT EXECUTE ON Proc_HienCTHDTheoTenSach to NhanVienThuNgan;
GRANT EXECUTE ON Proc_XuatHoaDon to NhanVienThuNgan;
GRANT EXECUTE ON Proc_ThemMaHoaDon to NhanVienThuNgan;
GRANT SELECT ON V_HienChiTietSach TO NhanVienThuNgan;
GO

-- 3. Tạo role cho QuanLiKho: thêm, sửa, xóa Tác giả, Sách, Phiếu nhập, CT Phiếu nhập --------------------------------
CREATE ROLE QuanLiKho
--Gán các quyền trên table cho role QuanLiKho
GRANT SELECT,INSERT,UPDATE, DELETE ON TacGia TO QuanLiKho
GRANT SELECT,INSERT,UPDATE, DELETE ON Sach TO QuanLiKho
GRANT SELECT,INSERT,UPDATE, DELETE ON PhieuNhap TO QuanLiKho
GRANT SELECT,INSERT,UPDATE, DELETE ON ChiTietPhieuNhap TO QuanLiKho
go
--. Gán quyền thực thi trên các procedure, function cho role QuanLiKho
GRANT EXECUTE ON Proc_XoaSach to QuanLiKho;
GRANT EXECUTE ON Proc_ThemSach to QuanLiKho;
GRANT EXECUTE ON Proc_SuaSach to QuanLiKho;

GRANT EXECUTE ON Proc_XoaPhieuNhap to QuanLiKho;
GRANT EXECUTE ON Proc_ThemPhieuNhap to QuanLiKho;
GRANT EXECUTE ON Proc_SuaPhieuNhap to QuanLiKho;

GRANT EXECUTE ON Proc_XoaChiTietPhieuNhap to QuanLiKho;
GRANT EXECUTE ON Proc_ThemChiTietPhieuNhap to QuanLiKho;
GRANT EXECUTE ON Proc_SuaChiTietPhieuNhap to QuanLiKho;

GRANT EXECUTE ON ThemTacGia to QuanLiKho;
GRANT EXECUTE ON CapNhatTacGia to QuanLiKho;
GRANT EXECUTE ON XoaTacGia to QuanLiKho;
GRANT EXECUTE ON Proc_XoaChiTietPhieuNhapTheoMaPhieuNhap to QuanLiKho;
GO



--THIẾT LẬP LIÊN QUAN TaiKhoan--------------------
--1. Tạo bảng TaiKhoan trong cơ sở dữ liệu, hỗ trợ việc phân quyền
CREATE TABLE TaiKhoan(
	TenDangNhap varchar(50) PRIMARY KEY,
	MatKhau varchar(50),
	Cap int
)
GO

--2. Proc tạo TaiKhoan
CREATE PROC Proc_ThemTaiKhoan
	@TenDangNhap varchar(50),
	@MatKhau varchar(50),
	@Cap int
AS
BEGIN 
	BEGIN 
		INSERT INTO TaiKhoan VALUES(@TenDangNhap,@MatKhau,@Cap)
	END 
END
GO

--3. Trigger thêm TaiKhoan
CREATE TRIGGER TG_ThemTaiKhoan ON TaiKhoan
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @TenDangNhap nvarchar(30), @MatKhau nvarchar(10), @Cap int
    DECLARE @sqlString nvarchar(2000)
    SELECT @TenDangNhap=i.TenDangNhap, @MatKhau=i.MatKhau, @Cap=i.Cap
    FROM inserted i

    IF EXISTS (SELECT 1 FROM TaiKhoan WHERE TenDangNhap = @TenDangNhap)
    BEGIN
        RAISERROR ('Tài khoản đã có trước đó!', 16, 1);
    END
    ELSE 
    BEGIN
        -- Insert account vào bảng Account
        INSERT INTO TaiKhoan(TenDangNhap, MatKhau, Cap)
        SELECT TenDangNhap, MatKhau, Cap
        FROM INSERTED
        --Tạo login
        SET @sqlString= 'CREATE LOGIN ' + @TenDangNhap + ' WITH PASSWORD = '''+ @MatKhau +''' '
        EXEC (@sqlString)
        --Tạo user
        SET @sqlString= 'CREATE USER ' + @TenDangNhap +' FOR LOGIN '+ @TenDangNhap
        EXEC (@sqlString)
        --Add thêm 1 user vào role
        IF @Cap = 1
            BEGIN
                SET @sqlString = 'ALTER ROLE admin_nhasach ADD MEMBER '+ @TenDangNhap;
            END

        ELSE IF @Cap = 2
            BEGIN
                SET @sqlString = 'ALTER ROLE NhanVienThuNgan ADD MEMBER '+ @TenDangNhap;
            END

        ELSE -- @Cap = 3
            BEGIN
                SET @sqlString = 'ALTER ROLE QuanLiKho ADD MEMBER ' + @TenDangNhap;
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
    SET @sqlString = 'KILL ' + Convert(NVARCHAR(20), @sessionID)
    EXEC(@sqlString)
END
BEGIN 
    BEGIN TRY
        -- Xóa User trong database
        SET @sqlString = 'DROP USER '+ @TenDangNhap
        EXEC (@sqlString)
        --Xóa login
        SET @sqlString = 'DROP LOGIN '+ @TenDangNhap
        EXEC (@sqlString)
        --Xóa tài khoản trong table Account
        DELETE FROM TaiKhoan WHERE TenDangNhap = @TenDangNhap
    END TRY
    BEGIN CATCH
        DECLARE @err nvarchar(MAX)
        SELECT @err = ERROR_MESSAGE()
        RAISERROR(@err,16,1)
    END CATCH
END
GO

--5. Proc thay đổi mật mật
CREATE OR ALTER PROC proc_ThayDoiMatKhau
@TenDangNhap varchar(10),
@MatKhau varchar(20)
as 
begin
	DECLARE @sql NVARCHAR(MAX);
	DECLARE @user NVARCHAR(10)
	DECLARE @MatKhauMoi NVARCHAR(20)
	SET @user = @TenDangNhap
    SET @MatKhauMoi = @MatKhau
	BEGIN TRANSACTION
	BEGIN TRY
		
		SET @sql = 'ALTER LOGIN [' + @user + '] WITH PASSWORD = ''' + @MatKhauMoi + '''';
		EXEC(@sql)

		UPDATE TaiKhoan set MatKhau = @MatKhauMoi WHERE TenDangNhap = @user;
	END TRY
	BEGIN CATCH
		declare @err nvarchar(max);
		set @err ='Không cập nhập được mật khẩu mới!';
		raiserror(@err, 16,1);
		rollback transaction;
		throw;
	END CATCH
	COMMIT TRANSACTION
end
GO

EXEC Proc_ThemTaiKhoan
	@TenDangNhap = 'admin',
	@MatKhau  = '123',
	@Cap = 1