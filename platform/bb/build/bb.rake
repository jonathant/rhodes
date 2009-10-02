#
def startmds
  mdshome =  $config["env"]["paths"][$config["env"]["bbver"]]["mds"]
  args = []
  args << "/c"
  args << "run.bat"

  Jake.run("cmd.exe",args, mdshome,true)
end 

def stopmds
  mdshome =  $config["env"]["paths"][$config["env"]["bbver"]]["mds"]
  args = []
  args << "/c"
  args << "shutdown.bat"

  Jake.run("cmd.exe",args, mdshome, true, true)
end 

def startsim
  bbver = $config["env"]["bbver"]
  sim = $config["env"]["paths"][bbver]["sim"]
  jde = $config["env"]["paths"][bbver]["jde"]
    
  command =  '"' + jde + "/simulator/fledge.exe\""
  args = []
  args << "/app=Jvm.dll"
  args << "/handheld=" + sim
  args << "/session=" + sim
  args << "/app-param=DisableRegistration"
  args << "/app-param=JvmAlxConfigFile:"+sim+".xml"
  args << "/data-port=0x4d44"
  args << "/data-port=0x4d4e"
  args << "/pin=0x2100000A"
  args << "/no-compact-filesystem"
    
  if bbver !~ /^4\.[012](\..*)?$/
    args << "/fs-sdcard=true"
  end
        
  args << "\"/app-param=JvmDebugFile:"+Jake.get_absolute($config["env"]["applog"]) +'"'

  Thread.new { Jake.run(command,args,jde + "/simulator",true) }
  $stdout.flush
end

def stopsim
  sim = $config["env"]["paths"][$config["env"]["bbver"]]["sim"]
  jde = $config["env"]["paths"][$config["env"]["bbver"]]["jde"]
    
  command =  '"' + jde + "/simulator/fledgecontroller.exe\""
  args = []
  args << "/session="+sim
  args << "/execute=Exit(true)"
  Jake.run(command,args, jde + "/simulator")
end

def manualsign
  java = $config["env"]["paths"]["java"] + "/java.exe"
  jde = $config["env"]["paths"][$config["env"]["bbver"]]["jde"]

  args = []
  args << "-jar"
  args << '"' + jde + "/bin/SignatureTool.jar\""
  args << "-r"
  args << $targetdir

  puts Jake.run(java,args)
  $stdout.flush

end

def autosign
  java = $config["env"]["paths"]["java"] + "/java.exe"
  jde = $config["env"]["paths"][$config["env"]["bbver"]]["jde"]

  args = []
  args << "-jar"
  args << '"' + jde + "/bin/SignatureTool.jar\""
  args << "-c"
  args << "-a"
  args << "-p"
  args << '"' + $config["build"]["bbsignpwd"] +'"'
  args << "-r"
  args << $targetdir

  puts Jake.run(java,args)
  $stdout.flush

end


namespace "config" do
  task :bb => ["config:common"] do
    bbpath = $config["build"]["bbpath"]
    $bbver = $config["env"]["bbver"]
    $builddir = bbpath + "/build"
    $bindir = bbpath + "/bin"
    $rhobundledir =  bbpath + "/RhoBundle"
    $srcdir =  $bindir + "/RhoBundle"
    $preverified = bbpath + "/preverified"
    $targetdir = bbpath + "/target/" + $bbver
    $rubyVMdir = bbpath + "/RubyVM"
    $excludelib = ['**/singleton.rb','**/rational.rb','**/rhoframework.rb','**/date.rb']
    $compileERB = bbpath + "/build/compileERB.rb"
    $tmpdir =  $bindir +"/tmp"
    $excludeapps = "public/js/iui/**,**/jquery*"

    $outfilebase = $config["env"]["appname"].nil? ? "rhodesApp" : $config["env"]["appname"]
    $outfilebase.gsub!(/ /,"_")
    
    $rhobundleimplib = $config["env"]["paths"][$bbver]["jde"] + "/lib/net_rim_api.jar;" +
      Jake.get_absolute($preverified+"/RubyVM.jar")
    $rhodesimplib = $rhobundleimplib + ";"+ Jake.get_absolute($preverified+"/RhoBundle.jar")
  end
end

namespace "build" do
  namespace "bb" do
    desc "Build rhoBundle"
    #XXX change to ns build, rhobundle
    task :rhobundle => :rubyvm do
      java = $config["env"]["paths"]["java"] + "/java.exe"
      jdehome = $config["env"]["paths"][$bbver]["jde"]
      jarexe =  $config["env"]["paths"]["java"] + "/jar.exe"

      #common bundle task goes here#
      Rake::Task["build:bundle:xruby"].execute

      rm_rf $srcdir

      #XXX make preverify function in Jake
      args = []
      args << "-classpath"
      args << '"' + jdehome + "/lib/net_rim_api.jar;"+$preverified+"/RubyVM.jar\""
      args << "-d"
      args << $preverified
      args << $bindir + "/RhoBundle.jar"
      puts Jake.run(jdehome + "/bin/preverify.exe",args)
      unless $? == 0
        puts "Error preverifying"
        exit 1
      end
      $stdout.flush

      cp $preverified + "/RhoBundle.jar", $rhobundledir + "/RhoBundle.jar"
      
    end

    desc "Build RubyVM"
    task :rubyvm => ["config:bb"] do
      javac = $config["env"]["paths"]["java"] + "/javac.exe"
      jdehome = $config["env"]["paths"][$bbver]["jde"]

      rubyvmfiles = File.readlines($builddir + '/RubyVM_build.files').map { |l| l.gsub!(/\\/,'/').strip! }

      if not uptodate?($preverified + '/RubyVM.jar',rubyvmfiles)

        mkdir_p $tmpdir + "/RubyVM" if not FileTest.exists? $tmpdir + "/RubyVM"
        mkdir_p  $targetdir if not FileTest.exists?  $targetdir
        mkdir_p  $preverified if not FileTest.exists?  $preverified

        args = []
        args << "-g"
        args << "-d"
        args << '"' +$tmpdir + '/RubyVM"'
        args << "-bootclasspath"
        args << '"' + $config["env"]["paths"][$bbver]["jde"] + '/lib/net_rim_api.jar"'
        args << "-source"
        args << "1.3"
        args << "-target"
        args << "1.3"
        args << "-nowarn"
        args << "@#{$builddir}/RubyVM_build.files"
        puts Jake.run(javac,args)
        unless $? == 0
          puts "Error compiling java code"
          exit 1
        end
        $stdout.flush
        #XXX Move to task/function
        args = []
        args << "-classpath"
        args << '"' + jdehome + "/lib/net_rim_api.jar\""
        args << "-d"
        args << $tmpdir + "/RubyVM.preverify"
        args << '"' + $tmpdir + "/RubyVM\""
        puts Jake.run(jdehome + "/bin/preverify.exe",args)
        unless $? == 0
          puts "Error preverifying"
          exit 1
        end
        $stdout.flush

        Jake.jar($preverified+"/RubyVM.jar", $builddir + "/RubyVM_manifest.mf", $tmpdir + "/RubyVM.preverify",true)
        $stdout.flush
      else
        puts 'RubyVM.jar is up to date'
        $stdout.flush
      end



      rm_rf $tmpdir
      mkdir_p $tmpdir
    end

    desc "Build rhodes"
    task :rhodes => [ :rubyvm, :rhobundle ] do
      javac = $config["env"]["paths"]["java"] + "/javac.exe"
      jde =  $config["env"]["paths"][$bbver]["jde"]
      jdehome = $config["env"]["paths"][$bbver]["jde"]

      sources = Dir.glob($builddir + "/../rhodes/resources/**/*") |
      File.readlines($builddir + '/hsqldb_build.files').map { |l| l.gsub!(/\\/,'/').strip! } |
      File.readlines($builddir +'/rhodes_build.files').map { |l| l.gsub!(/\\/,'/').strip! }

      sources.delete(nil)

      if not FileUtils.uptodate?($preverified + "/rhodes.jar",sources)

        vsrcdir = $builddir + "/../rhodes/platform/" + $bbver
        if !File.exist?( vsrcdir ) || !File.directory?( vsrcdir )
          vsrcdir = $builddir + "/../rhodes/platform/common"
        end

        vsrclist = $builddir + "/../bin/vsrc_build.files"

        fvsrc = File.new( vsrclist, "w" )
        Dir.glob( vsrcdir + "/**/*.java" ).each do |line|
          fvsrc.puts line
        end
        fvsrc.close

        args = []
        args << "-g"
        args << "-d"
        args << $tmpdir
        args << "-classpath"
        args << '"' + $bindir + "/RhoBundle.jar;"+$preverified+"/RubyVM.jar\""
        args << "-bootclasspath"
        args << '"' + jde + "/lib/net_rim_api.jar\""
        args << "-source"
        args << "1.3"
        args << "-target"
        args << "1.3"
        args << "-nowarn"
        args << "@#{vsrclist}"
        #args << "@RubyVM_build.files"
        args << "@#{$builddir}/hsqldb_build.files"
        args << "@#{$builddir}/rhodes_build.files"
        puts "\texecuting javac"
        puts Jake.run(javac,args)
        unless $? == 0
          puts "Error compiling java code"
          exit 1
        end
        $stdout.flush

        cp_r $builddir + "/../rhodes/resources", $tmpdir + "/resources"
        cp $config["env"]["app"] + "/icon/icon.png", $tmpdir +"/resources"
        
        Jake.jar($bindir + "/rhodes.jar", $builddir + "/manifest.mf", $tmpdir,true)
        $stdout.flush
        args = []
        args << "-classpath"
        args << '"' + $rhodesimplib + '"'
        args << "-d"
        args << '"' + $preverified + '"'
        args << '"' + $bindir + "/rhodes.jar\""
        puts Jake.run(jdehome + "/bin/preverify.exe",args)
        unless $? == 0
          puts "Error preverifying"
          exit 1
        end
        $stdout.flush

      else
        puts "rhodes up to date"
      end

    end
  end
end

namespace "package" do
  namespace "bb" do
    desc "Package rhoBundle"
    task :rhobundle => ["build:bb:rhobundle"] do
      Jake.rapc("RhoBundle",
        $targetdir,
        $rhobundleimplib ,
        '"' + Jake.get_absolute($preverified + "/RhoBundle.jar") + '"',
        "RhoBundle",
        $config["env"]["vendor"],
        $config["env"]["version"]
      )
      unless $? == 0
        puts "Error in RAPC"
        exit 1
      end
      cp $builddir + "/RhoBundle.alx", $targetdir if not FileUtils.uptodate?($targetdir + "/RhoBundle.alx", $builddir + "/RhoBundle.alx")

    end

    desc "Package rubyVM"
    task :rubyvm => "build:bb:rubyvm" do
      jdehome = $config["env"]["paths"][$bbver]["jde"]

      if not FileUtils.uptodate?($targetdir + '/RubyVM.cod',$preverified + "/RubyVM.jar")
        Jake.rapc("RubyVM",
          $targetdir,
          jdehome + "/lib/net_rim_api.jar",
          '"' + Jake.get_absolute($preverified + "/RubyVM.jar") +'"',
          "RubyVM",
          $config["env"]["vendor"],
          $config["env"]["version"]
        )
        unless $? == 0
          puts "Error in RAPC"
          exit 1
        end
        $stdout.flush
      else
        puts 'RubyVM .cod files are up to date'
        $stdout.flush
      end

    end

    desc "Package rhodesApp"
    task :rhodes => ["build:bb:rhodes"] do
      appname = $config["env"]["appname"].nil? ? "rhodesApp" : $config["env"]["appname"]

      if not FileUtils.uptodate?($targetdir + '/' + $outfilebase + '.cod',$preverified + "/rhodes.jar")
        Jake.rapc($outfilebase,
          $targetdir,
          $rhodesimplib,
          '"' + Jake.get_absolute( $preverified + "/rhodes.jar") +'"',
          appname,
          $config["env"]["vendor"],
          $config["env"]["version"],
          "resources/icon.png",
          false,
          true
        )
        unless $? == 0
          puts "Error in RAPC"
          exit 1
        end
        $stdout.flush
        cp $builddir + "/rhodesApp.alx", $targetdir + "/" + $outfilebase + ".alx"  if not FileUtils.uptodate?( $targetdir + "/"+$outfilebase+".alx", $builddir + "/rhodesApp.alx")
      else
        puts 'rhodes .cod files are up to date'
        $stdout.flush
      end
          
    end

    desc "Package all production (all parts in one package)"
    task :production => ["build:bb:rhodes"] do
      jdehome = $config["env"]["paths"][$bbver]["jde"]
      rm_rf $tmpdir
      mkdir_p $tmpdir

      rm_rf $targetdir
      mkdir_p $targetdir

      Jake.unjar($preverified + "/RubyVM.jar", $tmpdir)
      Jake.unjar($preverified + "/RhoBundle.jar", $tmpdir)
      Jake.unjar($preverified + "/rhodes.jar", $tmpdir)

      if $bbver =~ /^4\.[012](\..*)$/
        max_size = 65536
        Dir.glob( $tmpdir + "/**/*" ).each do |f|
          if File.size( f ) > max_size
            puts "File size of " + f + " is more than " + max_size.to_s + " bytes"
            puts "There is no ability to pack this file into .cod file for BB " + $bbver
            puts "Please reduce its size and try again"
            $stdout.flush
            Process.exit
          end
        end
      end

      Jake.jar($bindir + "/" + $outfilebase + ".jar",$builddir + "/manifest.mf",$tmpdir,true)

      appname = $config["env"]["appname"].nil? ? "rhodesApp" : $config["env"]["appname"]

      Jake.rapc($outfilebase,
        $targetdir,
        jdehome + "/lib/net_rim_api.jar",
        '"' + Jake.get_absolute( $bindir + "/" + $outfilebase + ".jar") +'"',
        appname,
        $config["env"]["vendor"],
        $config["env"]["version"],
        "resources/icon.png",
        false,
        true
      )
      unless $? == 0
        puts "Error in RAPC"
        exit 1
      end
      $stdout.flush
      cp $builddir +"/rhodesApp.alx", $targetdir + "/" + $outfilebase + ".alx" if not FileUtils.uptodate?( $targetdir+"/"+$outfilebase+".alx", $builddir + "/rhodesApp.alx")


    end

    desc "Package all dev (each part in separate package)"
    task :dev => [ :rubyvm,:rhobundle,:rhodes] do
    end
  end
end




namespace "device" do
  namespace "bb" do
    desc "Build and package dev for device"
    task :dev => "package:bb:dev" do

      #make into functions
      if $config["build"]["bbsignpwd"] and $config["build"]["bbsignpwd"] != ""
        autosign
      else
        manualsign
      end

      rm_rf $targetdir + "/web"
      mkdir_p $targetdir + "/web"

      cp $targetdir + "/RhoBundle.jad", $targetdir + "/web"
      cp $targetdir + "/"+$outfilebase+".jad", $targetdir + "/web"
      cp $targetdir + "/RubyVM.jad", $targetdir + "/web"

      Jake.unjar($targetdir + "/RhoBundle.cod", $targetdir + "/web")
      Jake.unjar($targetdir + "/"+$outfilebase+".cod", $targetdir + "/web")
      Jake.unjar($targetdir + "/RubyVM.cod", $targetdir + "/web")

    end

    desc "Build and package dev rhobundle for device"
    task :rhobundle => "package:bb:rhobundle" do

      if $config["build"]["bbsignpwd"] and $config["build"]["bbsignpwd"] != ""
        autosign
      else
        manualsign
      end

      rm_rf Dir.glob($targetdir + "/web/RhoBundle*.*")

      cp $targetdir + "/RhoBundle.jad", $targetdir + "/web"

      Jake.unjar($targetdir + "/RhoBundle.cod", $targetdir + "/web")

    end

    desc "Build and package for production"
    task :production => "package:bb:production" do

      if $config["build"]["bbsignpwd"] and $config["build"]["bbsignpwd"] != ""
        autosign
      else
        manualsign
      end

      rm_rf $targetdir + "/web"
      mkdir_p $targetdir + "/web"

      cp $targetdir + "/"+$outfilebase+".jad", $targetdir + "/web"

      Jake.unjar($targetdir + "/"+$outfilebase+".cod", $targetdir + "/web")

    end

  end
end

namespace "clean" do
  namespace "bb" do
    desc "Clean preverified jars"
    task :preverified => "config:bb" do
      rm_rf $preverified if File.exists? $preverified
      mkdir_p $preverified
    end

    desc "Clean packaged files"
    task :packaged => "config:bb" do
      rm_rf $targetdir
      mkdir_p $targetdir
    end

    desc "Clean temp dir"
    task :tempdir => "config:bb" do
      rm_rf $tmpdir
      mkdir_p $tmpdir
    end

    desc "Clean all"
    task :all => [:preverified,:packaged,:tempdir] do
      rm_rf $bindir
    end

  end
end

namespace "run" do
  namespace "bb" do
      task :stopmdsandsim => ["config:bb"] do
        stopsim  
        stopmds
      end

      desc "Starts mds and sim"
      task :startmdsandsim => ["config:bb"] do
        startmds
        startsim
      end
  end
  
  desc "Builds everything, loads and starts sim"
  task :bb => ["run:bb:stopmdsandsim", "package:bb:production"] do
    #sim = $config["env"]["paths"][$bbver]["sim"]
    jde = $config["env"]["paths"][$bbver]["jde"]
    
    cp_r Jake.get_absolute(File.join($targetdir,"/.")), jde + "/simulator"
    
    startmds
    startsim

    #    puts "sleeping to allow simulator to get started"
    #    sleep 45
  
    #    command = '"' + jde + "/simulator/fledgecontroller.exe\""
    #    args = []
    #    args << "/session="+sim
    #    args << "\"/execute=LoadCod(" + Jake.get_absolute(File.join($targetdir,"rhodesApp.cod")) + ")\""
  
    #    Jake.run(command,args, jde + "/simulator")
    $stdout.flush
  end
  
end

namespace "config" do
  task :checkbb do
    javahome = $config["env"]["paths"]["java"]
    jdehome = $config["env"]["paths"][$bbver]["jde"]
    mdshome = $config["env"]["paths"][$bbver]["mds"]

    puts "BBVER: " + $bbver
    puts "JAVAHOME: " + javahome
    puts "JDEHOME: " + jdehome
    puts "MDSHOME: " + mdshome

    if not FileTest.exists? javahome
      puts "JAVAHOME does not exist. Make sure you have the Java SDK installed and that build.yml has the correct path"
      throw "JAVAHOME missing"
    end

    if not FileTest.exists? javahome + "/javac.exe"
      puts "javac.exe not found. Make sure JAVAHOME points to a valid Java SDK"
      throw "javac missing"
    end

    if not FileTest.exists? javahome + "/java.exe"
      puts "java.exe not found. Make sure JAVAHOME points to a valid Java SDK"
      throw "java missing"
    end

    if not FileTest.exists? javahome + "/jar.exe"
      puts "jar.exe not found. Make sure JAVAHOME points to a valid Java SDK"
      throw "jar missing"
    end

    if not FileTest.exists? jdehome
      puts "JDEHOME does not exist. Make sure you have the Blackberry JDK installed and that build.yml has the correct path"
      throw "JDEHOME missing"
    end
    if not FileTest.exists? mdshome
      puts "MDSHOME does not exist. Make sure you have the Blackberry JDK installed and that build.yml has the correct path"
      throw "MDSHOME missing"
    end

    if not FileTest.exists? jdehome + "/bin/preverify.exe"
      puts "preverify.exe not found. Make sure JDEHOME points to a valid Blackberry JDK"
      throw "preverify missing"
    end

    if not FileTest.exists? jdehome + "/bin/rapc.jar"
      puts "rapc.jar not found. Make sure JDEHOME points to a valid Blackberry JDK"
      throw "rapc missing"
    end

    puts "Config appears valid"
  end

end

namespace "prebuild" do
  desc "Prebuild binaries for blackberry gems"
  task :bb => ["build:bb:rubyvm", "build:bb:rhodes"] do
    if File.exists? $preverified + "/RubyVM.jar" and File.exists? $preverified + "/rhodes.jar"
      prebuilt = "rhodes/rhodes-build/res/prebuilt/bb"

      rm_rf prebuilt if File.exists? prebuilt
      mkdir_p prebuilt

      cp $preverified + "/RubyVM.jar", prebuilt
      cp $preverified + "/rhodes.jar", prebuilt

      cp $builddir + "/MANIFEST.MF", prebuilt
      cp $builddir + "/rhodesApp.alx", prebuilt
      
    end
  end
end