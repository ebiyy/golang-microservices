package main

import (
    "fmt"
    "myproject/utils"
)

func main() {
    sum := utils.Add(5, 3)
    product := utils.Multiply(4, 2)
    
    fmt.Println("5 + 3 =", sum)
    fmt.Println("4 × 2 =", product)
}