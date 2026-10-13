#!/usr/bin/env bash
# Roda os testes automatizados e falha também se o Godot registrar erro de
# script durante eles (erro a cada quadro passa despercebido no jogo, mas
# custa desempenho no celular — já aconteceu na Academia).
#   tests/run_tests.sh              -> todos
#   tests/run_tests.sh ato2 combate -> só os arquivos com esses nomes
cd "$(dirname "$0")/.."
G="${GODOT:-/d/Godot/Godot_v4.7.2-stable_win64_console.exe}"
NOISE="Unreferenced static string|leaked|paged|Thread object|ObjectDB instances|resources still in use"

"$G" --headless --path . --import > /dev/null 2>&1
OUT=$("$G" --headless --path . --script res://tests/run_tests.gd -- "$@" 2>&1)
CODE=$?

echo "$OUT" | grep -E "^(==|  OK|  FALHA|[0-9]+ verificações)"
ERRORS=$(echo "$OUT" | grep -E "SCRIPT ERROR|^ERROR:" | grep -vE "$NOISE" | sort | uniq -c)
if [ -n "$ERRORS" ]; then
	echo ""
	echo "ERROS DO GODOT DURANTE OS TESTES:"
	echo "$ERRORS" | head -n 30
	echo "$OUT" | grep -A3 -E "SCRIPT ERROR|^ERROR:" | grep -E "^\s+\[[0-9]+\]" | sort | uniq | head -n 15
	exit 1
fi
exit $CODE
