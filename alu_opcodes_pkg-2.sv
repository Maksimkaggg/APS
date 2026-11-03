/* -----------------------------------------------------------------------------
* Project Name   : Architectures of Processor Systems (APS) lab work
* Organization   : National Research University of Electronic Technology (MIET)
* Department     : Institute of Microdevices and Control Systems
* Author(s)      : Andrei Solodovnikov
* Email(s)       : hepoh@org.miet.ru

See https://github.com/MPSU/APS/blob/master/LICENSE file for licensing details.
* ------------------------------------------------------------------------------
*/
package alu_opcodes_pkg;
localparam ALU_OP_WIDTH = 5;

// Арифметические операции
localparam ALU_ADD  = 5'b00000; // Сложение (+)
localparam ALU_SUB  = 5'b01000; // Вычитание (-)

// Логические операции
localparam ALU_XOR  = 5'b00100; // Исключающее ИЛИ (XOR / ^)
localparam ALU_OR   = 5'b00110; // Логическое ИЛИ (OR / |)
localparam ALU_AND  = 5'b00111; // Логическое И (AND / &)

// Операции сдвига
localparam ALU_SRA  = 5'b01101; // Арифметический сдвиг вправо (>>) *сохраняет знаковый бит
localparam ALU_SRL  = 5'b00101; // Логический сдвиг вправо (>>) *заполняет нулями
localparam ALU_SLL  = 5'b00001; // Логический сдвиг влево (<<)

// Операции сравнения (обычно используются для условных переходов)
localparam ALU_LTS  = 5'b11100; // Меньше, знаковое (<, signed)
localparam ALU_LTU  = 5'b11110; // Меньше, беззнаковое (<, unsigned)
localparam ALU_GES  = 5'b11101; // Больше или равно, знаковое (>=, signed)
localparam ALU_GEU  = 5'b11111; // Больше или равно, беззнаковое (>=, unsigned)
localparam ALU_EQ   = 5'b11000; // Равно (==)
localparam ALU_NE   = 5'b11001; // Не равно (!=)

// Операции установки флага (Set Less Than)
// Записывают 1 в регистр, если условие истинно, и 0, если ложно
localparam ALU_SLTS = 5'b00010; // Установить 1, если меньше (знаковое)
localparam ALU_SLTU = 5'b00011; // Установить 1, если меньше (беззнаковое)

endpackage