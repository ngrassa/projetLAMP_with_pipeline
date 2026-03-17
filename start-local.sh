#!/bin/bash

# ══════════════════════════════════════════════════════════════
#  start-local.sh — Lance le projetLAMP en local (WSL)
#  Récupère automatiquement le dernier tag DockerHub
#  Pr. Noureddine GRASSA — ISET Sousse
# ══════════════════════════════════════════════════════════════

set -e

DOCKER_USERNAME="grassa77"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$APP_DIR/.env"

echo ""
echo "══════════════════════════════════════════════════════"
echo "   🚀 ProjetLAMP — Démarrage local"
echo "══════════════════════════════════════════════════════"

# ── 1. Récupération du dernier tag DockerHub ──────────────────
echo ""
echo "🔍 Récupération du dernier tag depuis DockerHub..."

LATEST=$(curl -s \
  "https://hub.docker.com/v2/repositories/$DOCKER_USERNAME/projetlamp-webapp/tags/?page_size=1&ordering=last_updated" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
tags = data.get('results', [])
print(tags[0]['name'] if tags else 'local')
")

if [ -z "$LATEST" ] || [ "$LATEST" = "local" ]; then
  echo "⚠️  Aucun tag trouvé sur DockerHub → utilisation du tag 'local'"
  LATEST="local"
else
  echo "✅ Dernier tag : $LATEST"
fi

# ── 2. Mise à jour du .env ────────────────────────────────────
echo ""
echo "📝 Mise à jour du fichier .env..."

cat > "$ENV_FILE" << ENVEOF
IMAGE_TAG=$LATEST
DOCKER_USERNAME=$DOCKER_USERNAME
ENVEOF

echo "   IMAGE_TAG=$LATEST"
echo "   DOCKER_USERNAME=$DOCKER_USERNAME"

# ── 3. Arrêt propre de la stack existante ────────────────────
echo ""
echo "🛑 Arrêt de la stack existante (volumes inclus)..."
cd "$APP_DIR"
docker-compose down -v 2>/dev/null || true

# ── 4. Pull des nouvelles images ──────────────────────────────
if [ "$LATEST" != "local" ]; then
  echo ""
  echo "📦 Pull des images depuis DockerHub..."
  docker-compose pull
else
  echo ""
  echo "⚠️  Tag 'local' → pas de pull (images locales utilisées)"
fi

# ── 5. Démarrage de la stack ──────────────────────────────────
echo ""
echo "▶️  Démarrage de la stack..."
docker-compose up -d

# ── 6. Attente que la DB soit prête ──────────────────────────
echo ""
echo "⏳ Attente que MariaDB soit prête..."
for i in $(seq 1 20); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' rsi21_db 2>/dev/null || echo "unknown")
  if [ "$STATUS" = "healthy" ]; then
    echo "✅ Base de données prête"
    break
  fi
  echo "   Tentative $i/20 (status: $STATUS)..."
  sleep 3
done

# ── 7. Vérification finale ────────────────────────────────────
echo ""
echo "🔎 État des conteneurs :"
docker-compose ps

echo ""
echo "🌐 Test HTTP..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if echo "$HTTP_CODE" | grep -qE "^(200|301|302)"; then
  echo "✅ Application accessible → http://localhost (HTTP $HTTP_CODE)"
else
  echo "⚠️  HTTP $HTTP_CODE — vérifier les logs :"
  echo "   docker logs rsi21_webapp"
  echo "   docker logs rsi21_db"
fi

echo ""
echo "══════════════════════════════════════════════════════"
echo "   ✅ Stack LAMP déployée avec le tag : $LATEST"
echo "   🌍 http://localhost"
echo "══════════════════════════════════════════════════════"
echo ""
