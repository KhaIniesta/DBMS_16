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
    MaNXB NCHAR(10) REFERENCES NhaXuatBan(MaNXB), 
    TenTG NVARCHAR(50) NOT NULL, 
    LienHe NCHAR(15)
)

CREATE TABLE Sach(
    MaSach NCHAR(10) PRIMARY KEY, 
    MaTG NCHAR(10) REFERENCES TacGia(MaTG), 
    MaNXB NCHAR(10) REFERENCES NhaXuatBan(MaNXB), 
    TenSach NVARCHAR(100) NOT NULL, 
    SoLuongSach INT NOT NULL CHECK(SoLuongSach >= 0), 
    Gia MONEY NOT NULL, 
    TheLoai NVARCHAR(50) NOT NULL
)

CREATE TABLE PhieuNhap(
    MaPhieuNhap NCHAR(10) PRIMARY KEY, 
    MaNXB NCHAR(10) REFERENCES NhaXuatBan(MaNXB), 
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
    TongHD MONEY CHECK( TongHD >= 0), 
    NgayInHD DATETIME NOT NULL
)

CREATE TABLE ChiTietHoaDon(
    MaHD NCHAR(15) REFERENCES HoaDon(MaHD), 
    MaSach NCHAR(10) REFERENCES Sach(MaSach), 
    SoLuongBan INT CHECK (SoLuongBan > 0), 
    Gia MONEY NOT NULL,
    PRIMARY KEY (MaHD, MaSach)
)

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
DELETE FROM TacGia
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_VT','NXB_TH',N'Vãn Tình','902201833')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_KG','NXB_TG',N' Katrina Goldsaito ','2587024666')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_ACD','NXB_VH',N'Arthur Conan Doyle','5274893230')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_CM','NXB_TG',N'Cao Minh','397952541')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_TH','NXB_NN',N'Thomas Herris','2372324538')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_NNA','NXB_T',N'Nguyễn Nhật Ánh','987428432')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_SH','NXB_T',N'Stephen Hawking','5189176417')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_NNT','NXB_T',N'Nguyễn Ngọc Thuần','932780176')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_TX','NXB_T',N'Trịnh Xuân','372142564')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_THO','NXB_KD',N'Tô Hoài','984890830')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_JL','NXB_KD',N'Julie Lardon','3627152638')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_MA','NXB_KD',N'Mitch Albom','7152633351')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_VTP','NXB_KD',N'Vũ Trọng Phụng','373251252')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_LT','NXB_TG',N'Lê Trinh','392526143')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_THG','NXB_DTB',N'Thanh Hường','862511929')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_TV','NXB_DTB',N'Thất Vi','331362536')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_LCY','NXB_TG',N'Lim Chong Yah','8725169211')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_AG','NXB_VH',N'Antoine Galland','5726253321')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_CG','NXB_PNVN',N'Camilla Grebe','3172225163')											
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_NQM','NXB_PNVN',N'Nguyễn Quang Minh','9725136621')																					
insert into TacGia(MaTG,MaNXB,TenTG,LienHe) values ('TG_KL','NXB_DT',N'Kent Lineback','5268156222')											

-- Insert Data into Sach:
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('1','TG_MA','NXB_KD',N'Những ngày thứ ba với thầy Morrie','65','52000','Văn học nước ngoài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('2','TG_JL','NXB_KD',N'Thế giới tương lai - Nuôi nhân loại','50','60200','Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('3','TG_TH','NXB_KD',N'Dế Mèn phiêu lưu ký','125','35000','Văn học Việt Nam')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('4','TG_VTP','NXB_KD',N'Số đỏ','131','42000','Văn học Việt Nam')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('5','TG_NNA','NXB_T',N'Còn chút gì để nhớ','60','33000','Truyện dài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('6','TG_TX','NXB_T',N'Những con đường của ánh sáng','160','80000','Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('7','TG_NNT','NXB_T',N'Vừa nhắm mắt vừa mở cửa sổ','125','45000','Truyện dài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('8','TG_SH','NXB_T',N'Lược sử thời gian','90','115000','Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('9','TG_SH','NXB_T',N'Vũ trụ trong vỏ hạt dẻ','92','110000','Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('10','TG_CG','NXB_PNVN',N'Tiếng thét dưới băng','80','32000','Văn học nước ngoài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('11','TG_NQM','NXB_PNVN',N'Bí quyết để thành công ở trường đại học','50','50000','Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('12','TG_TH','NXB_NN',N'Sự im lặng của bầy cừu','135','92000','Trinh thám')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('13','TG_TH','NXB_NN',N'Rồng đỏ','68','114750','Tâm lý')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('14','TG_NNA','NXB_DTB',N'Tôi thấy hoa vàng trên cỏ xanh','160','125500','Truyện thiếu nhi')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('15','TG_TH','NXB_DTB',N'Bách khoa tri thức dành cho trẻ em','75','60000','Khoa học')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('16','TG_TV','NXB_DTB',N'Gió nam thầm thì','110','86000','Truyện dài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('17','TG_AG','NXB_VH',N'Nghìn lẻ một đêm','100','204000','Văn học nước ngoài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('18','TG_ACD','NXB_VH',N'Những cuộc phiêu lưu của Sherlock Holmes','72','63200','Trinh thám')																						
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('20','TG_VT','NXB_TH',N'Không tự khinh bỉ, không tự phí hoài','47','109000','Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('21','TG_VT','NXB_TH',N'Bạn đắt giá bao nhiêu','64','96000','Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('22','TG_VT','NXB_TH',N'Không sợ chậm, chỉ sợ dừng','81','94000','Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('23','TG_VT','NXB_TH',N'Lấy tình thâm để đổi đầu bạc','98','129000','Kỹ năng sống')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('24','TG_KL','NXB_DT',N'Thiên tài tập thể','200','89600','Tâm lý')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('25','TG_LCY','NXB_TG',N'Đông Nam á - chặng đường dài phía trước','135','76000','Văn học nước ngoài')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('26','TG_LT','NXB_TG',N'To be a Woman Doctor in Vietnam','60','90000','Tâm lý')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('27','TG_KG','NXB_TG',N'Âm thanh của sự im lặng','27','98000','Kinh dị')											
insert into Sach(MaSach,MaTG,MaNXB,TenSach,SoLuongSach,Gia,TheLoai) values ('28','TG_CM','NXB_TG',N'Thiên tài bên trái, kẻ điên bên phải','46','123000','Tâm lý')											

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
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD01',null,'2023-09-02 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD02',null,'2023-09-02 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD03',null,'2023-09-02 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD04',null,'2023-09-03 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD05',null,'2023-09-03 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD06',null,'2023-09-03 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD07',null,'2023-09-04 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD08',null,'2023-09-04 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD09',null,'2023-09-04 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD10',null,'2023-09-05 00:00:00')						
insert into HoaDon(MaHD,TongHD,NgayInHD) values ('HD11',null,'2023-09-05 00:00:00')						

-- Insert Data into ChiTietHoaDon:
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD01','1','15','780000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD01','2','20','1204000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD01','3','40','1400000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD01','4','30','1260000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD02','5','20','660000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD02','6','80','6400000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD02','7','35','1575000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD02','8','40','4600000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD02','9','30','3000000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD03','10','30','960000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD03','11','10','500000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD04','12','20','1840000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD04','13','30','3422500')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD05','14','85','10667500')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD05','15','40','2400000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD05','16','40','3440000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD06','17','50','10200000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD06','18','30','1896000')									
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD07','20','10','1090000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD07','21','5','480000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD08','22','30','2820000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD09','23','35','4515000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD09','24','90','8064000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD10','25','30','2280000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD10','26','25','2250000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD11','27','15','1470000')					
insert into ChiTietHoaDon(MaHD,MaSach,SoLuongBan,Gia) values ('HD11','28','15','1845000')	


--Insert data TongHD trong bang HoaDon tinh tu bang ChiTietHoaDon
update HoaDon
set TongHD = (select sum(Gia) tonggia from ChiTietHoaDon where HoaDon.MaHD = ChiTietHoaDon.MaHD group by ChiTietHoaDon.MaHD)
go

-- Xem thong tin sach trong kho
CREATE VIEW V_ThongTinSachTrongKho AS
SELECT s.MaTG, s.MaNXB, s.TenSach, s.SoLuongSach, s.Gia, s.TheLoai , ctpn.MaPhieuNhap, ctpn.SoLuongNhap
FROM Sach s INNER JOIN ChiTietPhieuNhap ctpn ON s.MaSach = ctpn.MaSach
GO

-- Xem chi tiết các hóa đơn
CREATE VIEW V_ChiTietCacHoaDon AS
SELECT hd.TongHD, hd.NgayInHD, cthd.MaSach, cthd.SoLuongBan, cthd.Gia
FROM HoaDon hd INNER JOIN ChiTietHoaDon cthd ON hd.MaHD = cthd.MaHD
GO

--Xem chi tiết các phiếu nhập
CREATE VIEW V_ChiTietCacPhieuNhap AS
SELECT pn.MaNXB, pn.NgayNhap, ctpn.MaSach, ctpn.SoLuongNhap
FROM PhieuNhap pn INNER JOIN ChiTietPhieuNhap ctpn ON pn.MaPhieuNhap = ctpn.MaPhieuNhap
GO

-- Trigger kiểm tra số lượng từng loại sách trong kho có đủ để bán hay không?
CREATE TRIGGER TG_KTSachTrongKho
ON ChiTietHoaDon
AFTER INSERT, UPDATE
AS
BEGIN 
	DECLARE @SoLuongBan INT, @SoLuongNhap INT,@SoLuongTon INT;
	--Tính tổng số lượng sách đã bán
	SELECT	@SoLuongBan = SoLuongBan 
	FROM ChiTietHoaDon;
	
	--Tính tổng số lượng sách đã nhập
	SELECT @SoLuongNhap = SoLuongNhap 
	FROM ChiTietPhieuNhap;
	
	--Tính tổng số lượng sách tồn kho
	SET @SoLuongTon = @SoLuongNhap - @SoLuongBan;

	-- Kiểm tra số lượng sách tồn kho có đủ để bán hay không
	IF @SoLuongTon < 0
	BEGIN
		RAISERROR('Số lượng sách trong kho không đủ để bán ', 16, 1);
		ROLLBACK TRANSACTION;	
	END
END;
