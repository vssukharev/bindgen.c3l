
module bindgen::bg @private;
import clang;

macro String String.normType(self) => self.strip("struct ");
macro String CXString.convert(self) => clang::getCString(self).str_view();
macro String CXString.convertToType(self) => self.convert().normType();

