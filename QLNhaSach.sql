CREATE DATABASE QLNhaSach
GO
USE QLNhaSach
GO

CREATE TABLE NhaXuatBan (
    MaNXB NCHAR(10) PRIMARY KEY,
    TenNXB NVARCHAR(50) NOT NULL,
    DiaChiNXB NVARCHAR(100),
    LienHe NCHAR(50) NOT NULL
)

CREATE TABLE TacGia(
    MaTG NCHAR(10) PRIMARY KEY, 
    MaNXB NCHAR(10) REFERENCES NhaXuatBan(MaNXB) ON DELETE SET NULL ON UPDATE CASCADE, 
    TenTG NVARCHAR(50) NOT NULL, 
    LienHe NCHAR(15)
)

CREATE TABLE Sach(
    MaSach NCHAR(10) PRIMARY KEY, 
    MaTG NCHAR(10) REFERENCES TacGia(MaTG) ON DELETE SET NULL ON UPDATE CASCADE, 
    MaNXB NCHAR(10) REFERENCES NhaXuatBan(MaNXB), 
    TenSach NVARCHAR(100) NOT NULL, 
    SoLuongSach INT NOT NULL CHECK(SoLuongSach >= 0), 
    Gia MONEY NOT NULL CHECK(Gia > 0), 
    TheLoai NVARCHAR(50) NOT NULL,
    Anh IMAGE
)

CREATE TABLE PhieuNhap(
    MaPhieuNhap NCHAR(10) PRIMARY KEY, 
    MaNXB NCHAR(10) REFERENCES NhaXuatBan(MaNXB) ON DELETE SET NULL ON UPDATE CASCADE, 
    NgayNhap DATETIME NOT NULL 
)

CREATE TABLE ChiTietPhieuNhap(
    MaPhieuNhap NCHAR(10) REFERENCES PhieuNhap(MaPhieuNhap), 
    MaSach NCHAR(10) REFERENCES Sach(MaSach), 
    SoLuongNhap INT NOT NULL CHECK (SoLuongNhap > 0),
    PRIMARY KEY (MaPhieuNhap, MaSach)
)

CREATE TABLE HoaDon(
    MaHD NCHAR(15) PRIMARY KEY, 
    TongHD MONEY CHECK( TongHD >= 0) DEFAULT 0, 
    NgayInHD DATETIME NOT NULL
)

CREATE TABLE ChiTietHoaDon(
    MaHD NCHAR(15) REFERENCES HoaDon(MaHD), 
    MaSach NCHAR(10) REFERENCES Sach(MaSach), 
    SoLuongBan INT CHECK (SoLuongBan > 0), 
    Gia MONEY NOT NULL DEFAULT 0 CHECK(Gia >= 0),
    PRIMARY KEY (MaHD, MaSach)
)

-- PHẦN TẠO CÁC TRIGGER:==========================================================================

-- 1. Kiểm tra thông tin sách lúc nhập kho có bị trùng không, nếu mã sách đã tồn tại và mã nxb của sách đúng với mã nxb ở phiếu nhập tương ứng thì tăng số lượng sách trong bảng sách
IF OBJECT_ID ('Trigger_TangSoLuongSach', 'TR') IS NOT NULL 
  DROP TRIGGER TG_Trigger_TangSoLuongSach; 
GO
CREATE TRIGGER TG_Trigger_TangSoLuongSach
ON ChiTietPhieuNhap
AFTER INSERT
AS
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
    END
    ELSE
    BEGIN
        -- Nếu không thỏa mãn điều kiện, thực hiện ROLLBACK
        ROLLBACK;
    END
END
GO

-- 2. Kiểm tra số lượng từng loại sách trong kho có đủ để bán không
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

--3. Trigger cap nhat so luong sach sau khi dat hang - xuat hoa don 

-- 3.a Sau khi đặt hàng - xuất hóa đơn
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

-- 3.b Sau khi xóa hoặc hủy đơn hàng - xóa khỏi danh sách hóa đơn
create trigger TG_SoLuongSauXoaDatHang on ChiTietHoaDon
for delete as
begin
	update Sach
	set SoLuongSach = SoLuongSach + (select SoLuongBan from deleted where MaSach = Sach.MaSach)
	from Sach join deleted on Sach.MaSach = deleted.MaSach
end;
go

-- 3.c Sau khi cập nhật lại số lượng sách trong hóa đơn
create trigger TG_SoLuongSauCapNhat on ChiTietHoaDon
after update as
begin
	update Sach
	set SoLuongSach = SoLuongSach - (select SoLuongBan from inserted where MaSach = Sach.MaSach)
	+ (select SoLuongBan from deleted where MaSach = Sach.MaSach)
	from Sach join deleted on Sach.MaSach = deleted.MaSach
end;
go

--  4. Tính giá của từng mặt hàng trong chi tiết hóa đơn = Giá(bảng sách) * số lượng(chi tiết hóa dơn)
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

----5. Trigger cập nhật tổng hóa đơn trong bảng hóa đơn 
-- 5.a Cập nhật lại tổng hóa đơn sau khi thêm sp (thêm giá) vào chi tiết hóa đơn
create trigger TG_TinhTongHoaDonKhiThem on ChiTietHoaDon
after update as
begin
	update HoaDon
	set TongHD = TongHD + (select sum(Gia) from inserted where MaHD = HoaDon.MaHD)
	from HoaDon join inserted on HoaDon.MaHD = inserted.MaHD
end;
go
-- 5.b Cập nhật lại tổng hóa đơn sau khi xóa sp ra khỏi chi tiết hóa đơn
create trigger TG_TinhTongHoaDonKhiXoa on ChiTietHoaDon
after delete as
begin
	update HoaDon
	set TongHD = TongHD - (select sum(Gia) from deleted where MaHD = HoaDon.MaHD)
	from HoaDon join deleted on HoaDon.MaHD = deleted.MaHD
end;
go
-- PHẦN INSERT DATA:==========================================================================

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
					

-- PHẦN VIEW =================================================================================

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
SELECT pn.MaNXB, pn.NgayNhap, ctpn.MaSach, ctpn.SoLuongNhap
FROM PhieuNhap pn INNER JOIN ChiTietPhieuNhap ctpn ON pn.MaPhieuNhap = ctpn.MaPhieuNhap
GO

-- 4.a View xuat tong doanh thu theo ngay

create view V_DTNgay as
select MaHD, Year(NgayInHD) Nam, Month(NgayInHD) Thang, Day(NgayInHD) Ngay from HoaDon
go

-- 4.b View xuat tong doanh thu theo thang
create view V_DTThang as
select MaHD, Year(NgayInHD) Nam, Month(NgayInHD) Thang, Day(NgayInHD) Ngay from HoaDon
go

-- 4.c View xuat tong doanh thu theo nam
create view V_DTNam as
select MaHD, Year(NgayInHD) Nam, Month(NgayInHD) Thang from HoaDon
go

-- 5. View xem so luong sach da ban trong ngay 
create view V_SoLuongSachBanTrongNgay as
select ChiTietHoaDon.MaSach,sum(SoLuongBan) TongSoLuongBan from HoaDon join ChiTietHoaDon on HoaDon.MaHD = ChiTietHoaDon.MaHD 
where (select cast(NgayInHD as date) ngayInHD from HoaDon) = cast(GetDate() as date) group by ChiTietHoaDon.MaSach
go

-- 6. View hiển thị chi tiết sách trong chi tiết hóa đơn
create view V_HienChiTietSach
as
	select Sach.MaSach, TacGia.TenTG, NhaXuatBan.TenNXB, Sach.TheLoai, Sach.SoLuongSach, Sach.Gia, Sach.TenSach, Sach.Anh
	from Sach join ChiTietHoaDon on Sach.MaSach = ChiTietHoaDon.MaSach 
	join HoaDon on ChiTietHoaDon.MaHD = HoaDon.MaHD 
	join TacGia on Sach.MaTG = TacGia.MaTG
	join NhaXuatBan on Sach.MaNXB = NhaXuatBan.MaNXB
go

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
-- Proc cho CRUD bảng HoaDon
-- Xuất thông tin hóa đơn
create procedure Proc_HienHoaDon 
as
begin
	select * from HoaDon
end
go

-- Hiện toàn bộ mã hóa đơn
create procedure Proc_TimKiemMaHD
as
begin
	select distinct MaHD, TongHD from HoaDon order by MaHD 
end
go

-- Tìm kiếm theo mã hóa đơn trong bảng hóa đơn
create procedure Proc_TimKiemTheoMaHD
	@MaHD nchar(15)
as
begin
	select TongHD from HoaDon where MaHD = @MaHD
end
go

-- Thêm mã hóa đơn
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

-- Cập nhật hóa đơn
create procedure Proc_CapNhatHoaDon
	@MaHD nchar(15),
	@NgayInHoaDon datetime
as
begin
	update HoaDon set MaHD = @MaHD, NgayInHD = @NgayInHoaDon
end
go

-- Xóa hóa đơn
create procedure Proc_XoaHoaDon
	@MaHD nchar(15)
as
begin
	delete from ChiTietHoaDon where MaHD = @MaHD
	delete from HoaDon where MaHD = @MaHD
end
go

-- Tìm kiếm toàn bộ Mã sách
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

-- Hiển thị chi tiết sách
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

-- Hiển thị sách theo mã sách
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

-- Proc cho CRUD bảng ChiTietHoaDon
-- Hiển thị chi tiết hóa đơn
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

-- Hiện CTHD theo mã hóa đơn
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


-- Thêm sách cho chi tiết hóa đơn
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

-- Xóa sách cho chi tiết hóa đơn
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

-- Cập nhật sách cho chi tiết hóa đơn
create procedure Proc_XoaSachCTHD
	@MaHD nchar(15),
	@MaSach nchar(10)
as
begin
	delete from ChiTietHoaDon where MaHD = @MaHD and MaSach = @MaSach
end
go

select * from Sach
select * from ChiTietHoaDon
select * from HoaDon

-----END----------------------------------------------------

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