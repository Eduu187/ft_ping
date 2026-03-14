NAME        = ft_ping
CC          = cc
CFLAGS      = -Wall -Wextra -Werror

SRC_DIR     = src/
OBJ_DIR     = obj/

FILES       = main.c \
              parse.c \
			  messages.c

SRCS        = $(addprefix $(SRC_DIR), $(FILES))
OBJS        = $(addprefix $(OBJ_DIR), $(FILES:.c=.o))


all: $(NAME)

$(NAME): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $(NAME)
	@echo "✅ $(NAME) criado com sucesso."

$(OBJ_DIR)%.o: $(SRC_DIR)%.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)

clean:
	@rm -rf $(OBJ_DIR)
	@echo "🧹 Objetos (.o) e pasta $(OBJ_DIR) removidos."

fclean: clean
	@rm -f $(NAME)
	@echo "🗑️  Executável $(NAME) removido."

re: fclean all

c: all clean

.PHONY: all clean fclean re c