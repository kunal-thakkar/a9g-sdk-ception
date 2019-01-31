
# This file was created by mkconfig.rb when ruby was built.  Any
# changes made to this file will be lost the next time ruby is built.

module Config
  RUBY_VERSION == "1.8.7" or
    raise "ruby lib version (1.8.7) doesn't match executable version (#{RUBY_VERSION})"

  TOPDIR = File.dirname(__FILE__).chomp!("/lib/ruby/1.8/i386-mswin32")
  DESTDIR = TOPDIR && TOPDIR[/\A[a-z]:/i] || '' unless defined? DESTDIR
  CONFIG = {}
  CONFIG["DESTDIR"] = DESTDIR
  CONFIG["MAJOR"] = "1"
  CONFIG["MINOR"] = "8"
  CONFIG["TEENY"] = "7"
  CONFIG["PATCHLEVEL"] = "374"
  CONFIG["prefix"] = (TOPDIR || DESTDIR + "")
  CONFIG["EXEEXT"] = ".exe"
  CONFIG["ruby_install_name"] = "ruby"
  CONFIG["RUBY_INSTALL_NAME"] = "ruby"
  CONFIG["RUBY_SO_NAME"] = "msvcr100-ruby18"
  CONFIG["SHELL"] = "$(COMSPEC)"
  CONFIG["BUILD_FILE_SEPARATOR"] = "\\"
  CONFIG["PATH_SEPARATOR"] = ";"
  CONFIG["CFLAGS"] = "-MD   -O2b2xty- "
  CONFIG["CPPFLAGS"] = "-D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE   "
  CONFIG["CXXFLAGS"] = ""
  CONFIG["FFLAGS"] = ""
  CONFIG["LDFLAGS"] = ""
  CONFIG["LIBS"] = "oldnames.lib user32.lib advapi32.lib shell32.lib wsock32.lib "
  CONFIG["exec_prefix"] = "$(prefix)"
  CONFIG["bindir"] = "$(exec_prefix)/bin"
  CONFIG["sbindir"] = "$(exec_prefix)/sbin"
  CONFIG["libexecdir"] = "$(exec_prefix)/libexec"
  CONFIG["datadir"] = "$(prefix)/share"
  CONFIG["sysconfdir"] = "$(prefix)/etc"
  CONFIG["sharedstatedir"] = "$(DESTDIR)/etc"
  CONFIG["localstatedir"] = "$(DESTDIR)/var"
  CONFIG["libdir"] = "$(exec_prefix)/lib"
  CONFIG["includedir"] = "$(prefix)/include"
  CONFIG["oldincludedir"] = "/usr/include"
  CONFIG["infodir"] = "$(prefix)/info"
  CONFIG["mandir"] = "$(prefix)/man"
  CONFIG["build"] = "i686-pc-mswin32"
  CONFIG["build_alias"] = "i686-mswin32"
  CONFIG["build_cpu"] = "i686"
  CONFIG["build_vendor"] = "pc"
  CONFIG["build_os"] = "mswin32"
  CONFIG["host"] = "i686-pc-mswin32"
  CONFIG["host_alias"] = "i686-mswin32"
  CONFIG["host_cpu"] = "i686"
  CONFIG["host_vendor"] = "pc"
  CONFIG["host_os"] = "mswin32"
  CONFIG["target"] = "i386-pc-mswin32"
  CONFIG["target_alias"] = "i386-mswin32"
  CONFIG["target_cpu"] = "i386"
  CONFIG["target_vendor"] = "pc"
  CONFIG["target_os"] = "mswin32"
  CONFIG["CC"] = "cl -nologo"
  CONFIG["CPP"] = "cl -nologo -E"
  CONFIG["YACC"] = "byacc"
  CONFIG["RANLIB"] = ""
  CONFIG["AR"] = "lib -nologo"
  CONFIG["ARFLAGS"] = "-machine:x86 -out:"
  CONFIG["LN_S"] = ""
  CONFIG["SET_MAKE"] = "MFLAGS = -$(MAKEFLAGS)"
  CONFIG["CP"] = "copy > nul"
  CONFIG["ALLOCA"] = ""
  CONFIG["DEFAULT_KCODE"] = ""
  CONFIG["OBJEXT"] = "obj"
  CONFIG["DLDFLAGS"] = "-link -incremental:no -debug -opt:ref -opt:icf -dll $(LIBPATH)"
  CONFIG["ARCH_FLAG"] = ""
  CONFIG["STATIC"] = ""
  CONFIG["CCDLFLAGS"] = ""
  CONFIG["LDSHARED"] = "cl -nologo -LD"
  CONFIG["DLEXT"] = "so"
  CONFIG["DLEXT2"] = "dll"
  CONFIG["LIBEXT"] = "lib"
  CONFIG["STRIP"] = ""
  CONFIG["EXTSTATIC"] = ""
  CONFIG["setup"] = "Setup"
  CONFIG["PREP"] = "miniruby.exe"
  CONFIG["EXTOUT"] = ".ext"
  CONFIG["ARCHFILE"] = ""
  CONFIG["RDOCTARGET"] = "install-nodoc"
  CONFIG["LIBRUBY_LDSHARED"] = "cl -nologo -LD"
  CONFIG["LIBRUBY_DLDFLAGS"] = " -def:msvcr100-ruby18.def"
  CONFIG["rubyw_install_name"] = "rubyw"
  CONFIG["RUBYW_INSTALL_NAME"] = "rubyw"
  CONFIG["LIBRUBY_A"] = "$(RUBY_SO_NAME)-static.lib"
  CONFIG["LIBRUBY_SO"] = "$(RUBY_SO_NAME).dll"
  CONFIG["LIBRUBY_ALIASES"] = ""
  CONFIG["LIBRUBY"] = "$(RUBY_SO_NAME).lib"
  CONFIG["LIBRUBYARG"] = "$(LIBRUBYARG_SHARED)"
  CONFIG["LIBRUBYARG_STATIC"] = "$(LIBRUBY_A)"
  CONFIG["LIBRUBYARG_SHARED"] = "$(LIBRUBY)"
  CONFIG["SOLIBS"] = ""
  CONFIG["DLDLIBS"] = ""
  CONFIG["ENABLE_SHARED"] = "yes"
  CONFIG["OUTFLAG"] = "-Fe"
  CONFIG["CPPOUTFILE"] = "-P"
  CONFIG["LIBPATHFLAG"] = " -libpath:\"%s\""
  CONFIG["RPATHFLAG"] = ""
  CONFIG["LIBARG"] = "%s.lib"
  CONFIG["LINK_SO"] = "$(LDSHARED) -Fe$(@) $(OBJS) $(LIBS) $(LOCAL_LIBS) $(DLDFLAGS) -implib:$(*F:.so=)-$(arch).lib -pdb:$(*F:.so=)-$(arch).pdb -def:$(DEFFILE)"
  CONFIG["LINK_SO"] << "\n" "@if exist $(@).manifest mt -nologo -manifest $(@).manifest -outputresource:$(@);2"
  CONFIG["LINK_SO"] << "\n" "@if exist $(@).manifest $(RM) $(@:/=\\).manifest"
  CONFIG["COMPILE_C"] = "$(CC) $(INCFLAGS) $(CFLAGS) $(CPPFLAGS) -c -Tc$(<:\\=/)"
  CONFIG["COMPILE_CXX"] = "$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -c -Tp$(<:\\=/)"
  CONFIG["COMPILE_RULES"] = "{$(hdrdir)}.%s{}.%s: {$(topdir)}.%s{}.%s: {$(srcdir)}.%s{}.%s: .%s.%s:"
  CONFIG["RULE_SUBST"] = "{.;$(VPATH)}%s"
  CONFIG["TRY_LINK"] = "$(CC) -Feconftest $(INCFLAGS) -I$(hdrdir) $(CPPFLAGS) $(CFLAGS) $(src) $(LOCAL_LIBS) $(LIBS) -link $(LDFLAGS) $(LIBPATH) $(XLDFLAGS)"
  CONFIG["COMMON_LIBS"] = "m"
  CONFIG["COMMON_MACROS"] = "WIN32_LEAN_AND_MEAN WIN32"
  CONFIG["COMMON_HEADERS"] = "winsock.h windows.h"
  CONFIG["DISTCLEANFILES"] = "vc*.pdb"
  CONFIG["EXPORT_PREFIX"] = " "
  CONFIG["arch"] = "i386-mswin32"
  CONFIG["sitearch"] = "i386-msvcr100"
  CONFIG["sitedir"] = "$(prefix)/lib/ruby/site_ruby"
  CONFIG["vendordir"] = "$(prefix)/lib/ruby/vendor_ruby"
  CONFIG["configure_args"] = "--with-make-prog=nmake --enable-shared=i386-mswin32"
  CONFIG["ruby_version"] = "$(MAJOR).$(MINOR)"
  CONFIG["rubylibdir"] = "$(libdir)/ruby/$(ruby_version)"
  CONFIG["archdir"] = "$(rubylibdir)/$(arch)"
  CONFIG["sitelibdir"] = "$(sitedir)/$(ruby_version)"
  CONFIG["sitearchdir"] = "$(sitelibdir)/$(sitearch)"
  CONFIG["vendorlibdir"] = "$(vendordir)/$(ruby_version)"
  CONFIG["vendorarchdir"] = "$(vendorlibdir)/$(sitearch)"
  CONFIG["topdir"] = File.dirname(__FILE__)
  MAKEFILE_CONFIG = {}
  CONFIG.each{|k,v| MAKEFILE_CONFIG[k] = v.dup}
  def Config::expand(val, config = CONFIG)
    val.gsub!(/\$\$|\$\(([^()]+)\)|\$\{([^{}]+)\}/) do |var|
      if !(v = $1 || $2)
	'$'
      elsif key = config[v = v[/\A[^:]+(?=(?::(.*?)=(.*))?\z)/]]
	pat, sub = $1, $2
	config[v] = false
	Config::expand(key, config)
	config[v] = key
	key = key.gsub(/#{Regexp.quote(pat)}(?=\s|\z)/n) {sub} if pat
	key
      else
	var
      end
    end
    val
  end
  CONFIG.each_value do |val|
    Config::expand(val)
  end
end
RbConfig = Config # compatibility for ruby-1.9
CROSS_COMPILING = nil unless defined? CROSS_COMPILING
