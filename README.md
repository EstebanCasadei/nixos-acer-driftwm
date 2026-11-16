# NixOS y driftwm en el Acer

`acer.nix` es el módulo donde se incorporan paquetes, servicios y ajustes del escritorio. El flake usa los mismos inputs que la configuración documentada para el host `nixos`.

## Preparar la laptop una vez

Clona el repositorio privado en `~/nixos-acer-driftwm` con una cuenta de GitHub que tenga acceso. Si usas HTTPS, puedes configurar tu sesión con [`gh auth login`](https://cli.github.com/manual/gh_auth_login) y [`gh auth setup-git`](https://cli.github.com/manual/gh_auth_setup-git).

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
sudo nixos-rebuild test --flake "path:$HOME/nixos-acer-driftwm#nixos" --no-update-lock-file
```

## Aplicar los próximos cambios

Cuando un cambio esté en `main`, ejecútalo desde una TTY si afecta al inicio de sesión o al compositor. Con `switch`, la nueva generación también queda seleccionada para el próximo arranque.

```bash
git -C "$HOME/nixos-acer-driftwm" pull --ff-only &&
sudo nixos-rebuild switch --flake "path:$HOME/nixos-acer-driftwm#nixos" --no-update-lock-file
```

Para volver a la generación anterior tras un `switch`, usa `sudo nixos-rebuild switch --rollback`. También puedes seleccionarla desde el menú de arranque. [Manual de NixOS](https://nixos.org/manual/nixos/stable/#sec-rollback)

## Estado de driftwm

Las notas de migración registran un fallo DRM al abrir driftwm con la pantalla interna. Para diagnosticarlo queda pendiente identificar el controlador gráfico y reproducir el fallo desde la TTY del Acer.
