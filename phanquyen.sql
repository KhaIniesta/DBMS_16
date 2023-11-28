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
    SET @sqlString = 'KILL ' + Convert(NVARCHAR(20), @sessionID)
    EXEC(@sqlString)
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


CREATE PROCEDURE Proc_CapNhatTaiKhoan
    @TenDangNhap VARCHAR(50),
    @MatKhauMoi VARCHAR(10),
    @CapMoi INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MatKhauHienTai NCHAR(10);
    DECLARE @CapHienTai INT;

    BEGIN TRY
        -- Bắt đầu transaction
        BEGIN TRANSACTION;

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
		
	-- Mật khẩu và cấp không thay đổi
	IF @MatKhauMoi = @MatKhauHienTai AND @CapMoi = @CapHienTai
    BEGIN
        RAISERROR ('Mật khẩu và cấp không có sự thay đổi!', 16, 1);
        RETURN; -- Kết thúc thủ tục
    END
END;

EXEC Proc_ThemTaiKhoan
	@TenDangNhap = 'admin_sach',
	@MatKhau  = '123',
	@Cap = 1

EXEC Proc_ThemTaiKhoan
	@TenDangNhap = 'thungan',
	@MatKhau  = '456',
	@Cap = 2

EXEC Proc_ThemTaiKhoan
	@TenDangNhap = 'qlkho',
	@MatKhau  = '789',
	@Cap = 3
