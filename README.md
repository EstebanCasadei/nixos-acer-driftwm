# NixOS y driftwm en el Acer

`acer.nix` es el módulo donde se incorporan paquetes, servicios y ajustes del escritorio. El flake usa los mismos inputs que la configuración documentada para el host `nixos`.

## Preparar la laptop una vez

Clona el repositorio en tu directorio personal. Si GitHub te pide acceso, configura tu sesión HTTPS con [`gh auth login`](https://cli.github.com/manual/gh_auth_login) y [`gh auth setup-git`](https://cli.github.com/manual/gh_auth_setup-git).

```bash
git clone https://github.com/EstebanCasadei/nixos-acer-driftwm.git "$HOME/nixos-acer-driftwm"
```

Copia la configuración actual y su lock desde la TTY del Acer. Si `configuration.nix` importa otros archivos por rutas relativas, copia también esos archivos bajo `local/` conservando sus rutas. Guarda las credenciales en archivos externos al clon y referencia sus rutas desde la configuración, porque Nix copia la fuente del flake al almacén local.

```bash
cd "$HOME/nixos-acer-driftwm" &&
mkdir -p local &&
cp -n /etc/nixos/configuration.nix /etc/nixos/hardware-configuration.nix local/ &&
cp -n /etc/nixos/flake.lock ./flake.lock
```

Git ignora `local/` y el lock inicial. `path:` permite que Nix lea esos archivos durante la evaluación. Compara el `flake.nix` del repositorio con `/etc/nixos/flake.nix` si modificaste sus dependencias desde que escribiste las notas de migración.

Prueba el primer despliegue desde una TTY. `test` activa la configuración durante el arranque actual y conserva la generación predeterminada del próximo arranque. Ejecuta `switch` después de comprobar que tienes acceso a la consola y que el resultado es el esperado. [Manual de NixOS](https://nixos.org/manual/nixos/stable/#sec-changing-config)

```bash
nix flake lock "path:$HOME/nixos-acer-driftwm" &&
sudo nixos-rebuild test --flake "path:$HOME/nixos-acer-driftwm#nixos" --no-update-lock-file
```

## Aplicar los próximos cambios

Cuando un cambio esté en `main`, ejecútalo desde una TTY si afecta al inicio de sesión o al compositor. Con `switch`, la nueva generación también queda seleccionada para el próximo arranque.

```bash
git -C "$HOME/nixos-acer-driftwm" pull --ff-only &&
sudo nixos-rebuild switch --flake "path:$HOME/nixos-acer-driftwm#nixos" --no-update-lock-file
```

Para volver a la generación anterior tras un `switch`, usa `sudo nixos-rebuild switch --rollback`. También puedes seleccionarla desde el menú de arranque. [Manual de NixOS](https://nixos.org/manual/nixos/stable/#sec-rollback)

## Diagnosticar driftwm desde el Acer

Si la prueba incluye un cambio en el flake, ejecuta `bash probar.sh` después de `git pull`. Ajusta el lock local, activa la compilación con `nixos-rebuild test` y ejecuta el diagnóstico. La generación predeterminada del próximo arranque se conserva.

Abre una TTY con tu usuario habitual y ejecuta lo siguiente. El script detiene `greetd` durante la prueba si estaba activo y lo vuelve a iniciar al salir. La prueba dura hasta 20 segundos, más hasta 5 segundos si hace falta forzar el cierre de driftwm.

```bash
cd "$HOME/nixos-acer-driftwm" &&
git pull --ff-only &&
bash ./diagnostico-driftwm.sh
```

El script crea un [issue](https://github.com/EstebanCasadei/nixos-acer-driftwm/issues) con el informe en cada ejecución y muestra el enlace. Si el repositorio es público, el informe también queda público. Usa tu sesión de GitHub CLI en el Acer y obtiene `gh` temporalmente con Nix si falta. Si el envío falla, muestra dónde guardó la copia local. [Envío de informes con GitHub CLI](https://cli.github.com/manual/gh_issue_create)

Para comprobar el touchpad desde la TTY, ejecuta `bash diagnostico-driftwm.sh touchpad`. Mueve un dedo al aparecer el aviso. El informe incluye el total de bytes recibidos del dispositivo.

Para reinicializar el controlador del PIXA3848 antes de medir, usa `bash diagnostico-driftwm.sh touchpad reset`. El reinicio afecta solo a ese dispositivo durante la sesión actual. Si falla y el touchpad desaparece, reinicia el Acer.
