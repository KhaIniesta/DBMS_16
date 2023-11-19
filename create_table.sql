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
    MaPhieuNhap NCHAR(10) REFERENCES PhieuNhap(MaPhieuNhap)ON UPDATE CASCADE, 
    MaSach NCHAR(10) REFERENCES Sach(MaSach) ON UPDATE CASCADE, 
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