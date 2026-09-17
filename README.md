```
    :::     ::::::.    :::. ...    :::  .,::      .: .,-:::::   :::    .,::::::   :::.   :::.    :::..,:::::: :::::::..   
 ;;;     ;;;`;;;;,  `;;; ;;     ;;;  `;;;,  .,;;,;;;'````'   ;;;    ;;;;''''   ;;`;;  `;;;;,  `;;;;;;;'''' ;;;;``;;;;  
 [[[     [[[  [[[[[. '[[[['     [[[    '[[,,[[' [[[          [[[     [[cccc   ,[[ '[[,  [[[[[. '[[ [[cccc   [[[,/[[['  
 $$'     $$$  $$$ "Y$c$$$$      $$$     Y$$$P   $$$          $$'     $$""""  c$$$cc$$$c $$$ "Y$c$$ $$""""   $$$$$$c    
o88oo,.__888  888    Y8888    .d888   oP"``"Yo, `88bo,__,o, o88oo,.__888oo,__ 888   888,888    Y88 888oo,__ 888b "88bo,
""""YUMMMMMM  MMM     YM "YmmMMMM"",m"       "Mm, "YUMMMMMP"""""YUMMM""""YUMMMYMM   ""` MMM     YM """"YUMMMMMMM   "W"    
```

<p align="center">
  <b>limpeza multi-distro para Linux, direto do terminal</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/shell-bash-89e051?logo=gnu-bash&logoColor=white" />
  <img src="https://img.shields.io/badge/license-MIT-blue" />
  <img src="https://img.shields.io/badge/platform-Linux-yellow?logo=linux&logoColor=white" />
  <img src="https://img.shields.io/badge/status-active-brightgreen" />
</p>

<p align="center">
  <a href="#instalação">Instalação</a> •
  <a href="#uso">Uso</a> •
  <a href="#compatibilidade">Compatibilidade</a> •
  <a href="#flags">Flags</a> •
  <a href="#contribuindo">Contribuindo</a>
</p>

---

```
 ________________________________________ 
( The best cure for insomnia is to get a )
( lot of sleep. -W.C. Fields             )
 ---------------------------------------- 
        o   ^__^
         o  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

## O que é

**linuxclear** detecta sozinho seu gerenciador de pacotes (`pacman`, `apt`, `dnf`, `zypper`, `apk`, `xbps`) e limpa o que já não serve mais no seu sistema — cache velho, pacotes órfãos, logs, lixeira — com um menu interativo colorido em vez de uma pilha de comandos pra decorar.

```
┌─────────────────────────────────────────────┐
│  ✔  cache de pacotes        ✔  journald      │
│  ✔  pacotes órfãos          ✔  lixeira       │
│  ✔  /tmp e /var/tmp         ✔  thumbnails    │
│  ✔  cache do usuário        ✔  core dumps    │
└─────────────────────────────────────────────┘
```

---

## Instalação

```bash
git clone https://github.com/Rixadi/Linuxclear.git
cd Linuxclear
chmod +x linuxclear.sh
```

## Uso

```bash
./linuxclear.sh
```

Isso abre o menu interativo:

```
╔═══════════════════════════════════════════════╗
║   linuxclear — o que vamos limpar hoje?        ║
╠═══════════════════════════════════════════════╣
║  [1] Limpeza leve                              ║
║      cache antigo, órfãos, journal, /tmp       ║
║                                                 ║
║  [2] Limpeza profunda (lá ele)                 ║
║      tudo da leve + zera cache do usuário,     ║
║      /tmp e /var/tmp por completo              ║
╚═══════════════════════════════════════════════╝
```

Ou direto por flags, sem menu:

```bash
./linuxclear.sh -t          # limpa e esvazia a lixeira
./linuxclear.sh -b -t -y    # backup + lixeira + sem perguntar nada
./linuxclear.sh -h          # ver todas as opções
```

## Flags

| Flag | O que faz |
|:---:|---|
| `-b` | Backup com Timeshift antes de limpar |
| `-t` | Esvaziar a lixeira |
| `-r` | Reiniciar ao final |
| `-a` | Modo agressivo (limpeza profunda) |
| `-y` | Não perguntar nada (modo automático) |
| `-h` | Ajuda |

---

## Compatibilidade

```
  ✔ testado    ~ implementado, sem testes reais    ✘ sem suporte de pacotes
```

| Distro | Gerenciador | Status |
|---|:---:|:---:|
| Arch / Manjaro / EndeavourOS | pacman | ✔ |
| Ubuntu / Debian | apt | ✔ |
| Fedora | dnf | ~ |
| openSUSE | zypper | ~ |
| Alpine | apk | ~ |
| Void Linux | xbps | ~ |
| Gentoo, NixOS, outras | — | ✘ *(limpeza genérica ainda funciona)* |

> Testou numa distro marcada com `~`? Abra uma [issue](../../issues) contando o resultado — isso ajuda a fechar o suporte de verdade.

---

## ⚠️ Aviso

Este script roda comandos com `sudo` em diretórios e pacotes do sistema. Dê uma lida no código antes de rodar em produção. Ele nunca roda como root direto — pede privilégio só quando precisa, e avisa quando pula alguma etapa por falta de `sudo`.

## Contribuindo

```
   PRs são bem-vindos, especialmente:
   → testes reais em Fedora / openSUSE / Alpine / Void
   → correções de comandos que não se comportaram como esperado
```

1. Faça um fork
2. Crie uma branch (`git checkout -b minha-melhoria`)
3. Commit (`git commit -m 'add: melhoria X'`)
4. Push (`git push origin minha-melhoria`)
5. Abra um Pull Request

## Licença

MIT — veja [LICENSE](LICENSE).

---

<p align="center">
  <sub> <a href="#">pwd404</a></sub>
</p>
