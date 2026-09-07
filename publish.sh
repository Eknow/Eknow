#!/usr/bin/env bash
# Publica el README de perfil en GitHub.
# Uso: ./publish.sh TU_USUARIO_DE_GITHUB
set -euo pipefail

GH="${HOME}/.local/bin/gh"
USER_NAME="${1:-}"

if [[ -z "$USER_NAME" ]]; then
  echo "Uso: $0 TU_USUARIO_DE_GITHUB"
  echo "Ejemplo: $0 Eknow"
  exit 1
fi

if ! "$GH" auth status >/dev/null 2>&1; then
  echo "No hay sesión en GitHub. Ejecuta primero:"
  echo "  $GH auth login -w -p https"
  exit 1
fi

AUTH_USER="$("$GH" api user --jq .login)"
if [[ "$AUTH_USER" != "$USER_NAME" ]]; then
  echo "Atención: estás logueado como '$AUTH_USER', pero pediste '$USER_NAME'."
  echo "El repo de perfil debe llamarse exactamente como tu usuario: $AUTH_USER/$AUTH_USER"
  USER_NAME="$AUTH_USER"
  echo "Usaré: $USER_NAME"
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# Sustituir placeholder en el README
sed -i "s/TU_USUARIO/${USER_NAME}/g" README.md

# Crear repo especial de perfil si no existe
if ! "$GH" repo view "${USER_NAME}/${USER_NAME}" >/dev/null 2>&1; then
  echo "Creando repo ${USER_NAME}/${USER_NAME} (público, con README especial de perfil)..."
  "$GH" repo create "${USER_NAME}/${USER_NAME}" \
    --public \
    --description "Perfil de ${USER_NAME}" \
    --source=. \
    --remote=origin \
    --push
else
  echo "El repo ya existe. Configurando remote y haciendo push..."
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/${USER_NAME}/${USER_NAME}.git"
  else
    git remote set-url origin "https://github.com/${USER_NAME}/${USER_NAME}.git"
  fi
  git add README.md
  git commit -m "Update profile README" || true
  git push -u origin main
fi

echo ""
echo "Listo. Abre tu perfil:"
echo "  https://github.com/${USER_NAME}"
