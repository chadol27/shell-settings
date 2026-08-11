# shell-settings

```bash
sudo apt update
sudo apt install -y zsh git curl fzf

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

chsh -s "$(which zsh)"
exec zsh
```
```zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

git clone https://github.com/zsh-users/zsh-completions \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions

git clone https://github.com/Aloxaf/fzf-tab \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab

git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

mkdir -p "$HOME/.config"

git clone https://github.com/chadol27/shell-settings "$HOME/.config/shell-settings"

[ -e "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
ln -s "$HOME/.config/shell-settings/.zshrc" "$HOME/.zshrc"

[ -e "$HOME/.p10k.zsh" ] || [ -L "$HOME/.p10k.zsh" ] && rm "$HOME/.p10k.zsh"
ln -s "$HOME/.config/shell-settings/.p10k.zsh" "$HOME/.p10k.zsh"
```
