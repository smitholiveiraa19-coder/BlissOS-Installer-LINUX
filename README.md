Preparação: Tenha o arquivo instalar_bliss.sh e a ISO renomeada como BLISSOS.iso na sua pasta Downloads.

Execução: Abra o terminal na pasta e rode sudo ./instalar_bliss.sh para iniciar.

Dependências: O script detecta e instala sozinho ferramentas como 7zip e grub-tools se você não as tiver.

Extração: Ele abre a ISO e extrai apenas o Kernel e o Sistema para uma nova pasta /blissos na raiz do seu HD.

Persistência: O script cria automaticamente uma pasta /data, garantindo que seus apps e arquivos no Android sejam salvos.

Dual-Boot: Ele identifica seu Linux e adiciona o Bliss OS no menu de inicialização (GRUB) sem apagar nada.

Logs: Tudo o que acontece é registrado em tempo real e salvo em /var/log/bliss_install.log.

Segurança: Antes de terminar, ele faz um check-up dos arquivos para garantir que o boot não vai dar erro.

Interface: O processo usa cores (Verde/Vermelho) e barra de progresso para você saber exatamente o que está ocorrendo.

Finalização: Ao final, o script pergunta se você quer reiniciar para já entrar no seu novo Android.
