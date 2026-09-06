# Dotfiles Bootstrap

> Arranque de una línea para [dotfiles](https://github.com/alejakun/dotfiles)

Este repositorio existe por una sola razón: **`dotfiles` es privado**, así que un
`curl` a su contenido no funciona sin credencial — y la credencial es justo lo
que una Mac recién formateada todavía no tiene. Un repositorio público rompe ese
círculo.

Es un **lanzador, no un instalador**. Instala lo mínimo para poder clonar, y
entrega el control. Los paquetes, symlinks, configuración y logging viven en el
repositorio principal.

---

## Uso

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alejakun/bootstrap/master/macos/bootstrap.sh)
```

Solo macOS. El resto de los hosts tiene su propio instalador dentro de
`dotfiles` (`hosts/debian/`, `hosts/synology/`, …).

---

## Qué hace, en orden

| # | Paso | Por qué |
|---|---|---|
| 1 | Comprueba que sea macOS | El resto de los hosts usan otro instalador |
| 2 | Instala **Homebrew** | Trae las Xcode Command Line Tools, y con ellas `git` |
| 3 | Instala **GitHub CLI** | Único camino a `gh` sin credencial previa |
| 4 | `gh auth login -w -s admin:public_key` | El navegador, **una sola vez** |
| 5 | Genera `~/.ssh/id_ed25519` | La identidad de este equipo |
| 6 | `gh ssh-key add` | La registra en GitHub **sin navegador** |
| 7 | Clona por SSH y ejecuta `install.sh --all` | Entrega el control |

### Por qué el orden importa

Registrar la llave **antes** de clonar es lo que permite que el primer clon ya
sea por SSH. `gh auth` entrega un token de API, no una credencial de git: HTTPS
nunca se usa como transporte.

Eso mantiene una sola política —la de
[`docs/ssh-identities.md`](https://github.com/alejakun/dotfiles/blob/master/docs/ssh-identities.md)—
en lugar de dos. La versión anterior de este script clonaba por HTTPS y no creaba
llave, y una máquina arrancada así **no podía aprovisionar el homelab**: el agent
forwarding no llevaba ninguna identidad de GitHub.

### El scope que no viene por defecto

`gh auth login` pide `repo`, `read:org` y `gist`. Registrar una llave necesita
`admin:public_key`, que **no** está incluido. Pedirlo desde el login evita tener
que volver al navegador con `gh auth refresh` a mitad del arranque.

---

## Lo que este repositorio deliberadamente NO hace

Todo esto vive en `dotfiles` y duplicarlo aquí solo crea deriva:

| No lo hace | Quién lo hace |
|---|---|
| Instalar paquetes | `brew/Brewfile` |
| Configurar git | `git/.gitconfig` y `git/macos.gitconfig.local` |
| Logging y reportes | El instalador ya escribe a `~/.dotfiles-install-logs/` |
| Xcode CLI Tools explícitas | El instalador de Homebrew las instala solo |

La única duplicación intencional es la generación de la llave (paso 5), que
repite a `bin/gh-setup-ssh`. Es inevitable: esa herramienta vive dentro del
repositorio privado, que en ese momento no se puede clonar. **Si cambia una,
cambia la otra.**

---

## Si algo falla

El script se detiene en el primer error y dice cuál fue. Los puntos donde se
atora, en orden de probabilidad:

**`gh` no tiene el permiso.** Si el paso 6 falla con un error de scope:

```bash
gh auth refresh -h github.com -s admin:public_key
```

**GitHub no reconoce la llave** (paso 6, verificación):

```bash
ssh -vT git@github.com
gh ssh-key list
```

**`~/.dotfiles` ya existe.** El script lo conserva y salta el clon a propósito;
no borra nada. Si quieres empezar de cero, mueve el directorio tú.

**Después del clon.** A partir del paso 7 manda el instalador del repositorio
principal; sus logs están en `~/.dotfiles-install-logs/` y su
[troubleshooting](https://github.com/alejakun/dotfiles/blob/master/docs/troubleshooting.md)
aplica desde ahí.

---

## Estado de verificación

Los pasos 4 y 6 —el scope `admin:public_key` y `gh ssh-key add` sin navegador—
están confirmados **por documentación**, no por ejecución: no ha habido una Mac
en blanco desde que se escribieron. Primera corrida real pendiente.

---

## Requisitos

- macOS 11 (Big Sur) o posterior
- Conexión a internet
- Permisos de administrador (Homebrew y las Command Line Tools los piden)

---

## Relacionado

- [dotfiles](https://github.com/alejakun/dotfiles) — repositorio principal (privado)
- [`windows/`](../windows/) — el equivalente para Windows, en este mismo repositorio
