set WORKING_DIR=%CD%

cd %~dp0

@echo Compiling Erlang/Elixir files...

cd %~dp0\server\beam\tau

set MIX_ENV=prod
cmd /c mix deps.clean --unused
cmd /c mix deps.compile
cmd /c mix tau.release

cd %WORKING_DIR%
