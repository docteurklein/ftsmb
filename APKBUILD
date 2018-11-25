pkgname=postgresql
pkgver=11.1
pkgrel=0
pkgdesc="A sophisticated object-relational DBMS"
url="https://www.postgresql.org/"
arch="all"
license="PostgreSQL"
depends="postgresql-client tzdata"
install="$pkgname.pre-upgrade"
pkgusers="postgres"
pkggroups="postgres"
checkdepends="diffutils"
depends_dev="openssl-dev"
makedepends="$depends_dev libedit-dev zlib-dev libxml2-dev util-linux-dev"
subpackages="libpq $pkgname-libs $pkgname-client"
source="https://ftp.postgresql.org/pub/source/v$pkgver/$pkgname-$pkgver.tar.bz2
	parallel_subtransaction.patch
	"
builddir="$srcdir/$pkgname-$pkgver"
options="!checkroot"


prepare() {
	default_prepare
	cd "$builddir"

	cp -al "$builddir" "$builddir"~py3
}

build() {
	cd "$builddir"
	_configure && make world
}

# Note: (...) instead of {...} is NOT a typo!
_configure() (
	export CFLAGS="${CFLAGS/-Os/-O2}"
	export CPPFLAGS="${CPPFLAGS/-Os/-O2}"

	./configure \
		--build=$CBUILD \
		--host=$CHOST \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--with-system-tzdata=/usr/share/zoneinfo \
		--with-libedit-preferred \
		--with-libxml \
		--with-openssl \
		--with-uuid=e2fs \
		--disable-rpath
)

package() {
	cd "$builddir"

	make DESTDIR="$pkgdir" install

	cd "$pkgdir"

	install -d -m750 -o postgres -g postgres \
		./var/lib/postgresql \
		./var/log/$pkgname
}

libpq() {
	pkgdesc="PostgreSQL libraries"
	depends=""

	_submv usr/lib/libpq.so.*
}

libs() {
	depends=""
	default_libs
}

client() {
	pkgdesc="PostgreSQL client"
	depends=""

	cd "$pkgdir"/usr/bin
	mkdir -p "$subpkgdir"/usr/bin
	mv clusterdb \
		createdb \
		createuser \
		dropdb \
		dropuser \
		pg_basebackup \
		pg_dump \
		pg_dumpall \
		pg_isready \
		pg_receivewal \
		pg_recvlogical \
		pg_restore \
		psql \
		reindexdb \
		vacuumdb \
		"$subpkgdir"/usr/bin/
}

_submv() {
	local path; for path in "$@"; do
		mkdir -p "$subpkgdir/${path%/*}"
		mv "$pkgdir"/$path "$subpkgdir"/${path%/*}/
	done
}

