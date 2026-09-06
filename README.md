# bootstrap

> Cómo una máquina nueva llega a tener [mis dotfiles](https://github.com/alejakun/dotfiles).

Este repositorio es **público por necesidad, no por generosidad**: el repo de
dotfiles es privado, así que un `curl` a su contenido no funciona sin credencial
— y la credencial es justo lo que una máquina recién formateada todavía no tiene.
Un repositorio público rompe ese círculo.

Son **lanzadores, no instaladores**. Instalan lo mínimo para poder clonar y
entregan el control. Los symlinks, las shells y la configuración viven en el repo
privado.

---

## macOS

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alejakun/bootstrap/master/macos/bootstrap.sh)
```

Un solo comando: Homebrew (que trae las Xcode Command Line Tools), GitHub CLI,
autenticación en el navegador **una vez**, la llave SSH de este equipo registrada
sin navegador, el clon por SSH, y el instalador.

Detalle en [`macos/README.md`](macos/README.md).

## Windows

Tres fases, y la separación **no es capricho**: `prepare-machine.ps1` tiene que
correr elevado y el resto no debe. La frontera de privilegios parte el flujo.

```powershell
# 1. Preparación de máquina (elevada, una sola vez)
iwr -useb https://raw.githubusercontent.com/alejakun/bootstrap/master/windows/prepare-machine.ps1 | iex

# 2. Paquetes
$env:DOTFILES_PROFILE="pro"; iwr -useb https://raw.githubusercontent.com/alejakun/bootstrap/master/windows/bootstrap.ps1 | iex

# 3. Llave de este equipo, clon, y configuración
iwr -useb https://raw.githubusercontent.com/alejakun/bootstrap/master/windows/get-dotfiles.ps1 | iex
```

Detalle, perfiles y grupos opcionales en [`windows/README.md`](windows/README.md).

---

## La regla que comparten

**La llave SSH se registra ANTES de clonar.** `gh auth` entrega un token de API,
no una credencial de git, así que HTTPS nunca se usa como transporte: el primer
clon ya es por SSH.

Eso mantiene **una sola política de identidades** en vez de dos. La versión
anterior del arranque de macOS clonaba por HTTPS y no creaba llave, y una máquina
así **no puede aprovisionar el homelab** — el agent forwarding no lleva ninguna
identidad de GitHub. No es teórico: un nodo pasó un mes congelado exactamente por
eso, reportando éxito en cada corrida.

Ver [`docs/ssh-identities.md`](https://github.com/alejakun/dotfiles/blob/master/docs/ssh-identities.md)
en el repo privado.

## La duplicación que no se puede quitar

La generación y registro de la llave existe **tres veces**:

| Copia | Para |
|---|---|
| `macos/bootstrap.sh` | Arranque de una Mac |
| `windows/get-dotfiles.ps1` | Arranque de Windows |
| `dotfiles/bin/gh-setup-ssh` | Rotación, y hosts Unix |

No se pueden fusionar. Las dos primeras viven aquí, en público, que es
precisamente lo que las hace alcanzables antes de que exista una credencial; y la
de Windows además es PowerShell. **Si cambia una, cambian las tres** — que las dos
primeras estén ahora en el mismo repositorio, una carpeta al lado de la otra, es
toda la mitigación disponible.

## Estructura

```
bootstrap/
├── macos/
│   └── bootstrap.sh            un script, siete pasos
└── windows/
    ├── prepare-machine.ps1     cambios de máquina (elevado)
    ├── bootstrap.ps1           descarga y llama al de abajo
    ├── install-packages.ps1    escalera mini/base/pro + grupos opcionales
    ├── get-dotfiles.ps1        llave, clon y entrega
    ├── winget/                 listas de paquetes
    └── npm/
```

## Historia

Hasta el 2026-09-05 esto eran dos repositorios: `dotfiles-win` y
`dotfiles-bootstrap`. Hacían el mismo trabajo para plataformas distintas y
estaban separados por accidente histórico, con nombres que mentían — uno no
contenía ni un dotfile y el otro decía ser genérico siendo solo de macOS. Las dos
historias se conservan completas en este repositorio.
