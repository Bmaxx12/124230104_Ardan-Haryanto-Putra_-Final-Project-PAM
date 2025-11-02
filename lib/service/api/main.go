package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
)


type ExchangeAPIResponse struct {
	Result          string             `json:"result"`
	ConversionRates map[string]float64 `json:"conversion_rates"`
}

func convertCurrency(from, to string, amount float64) (float64, float64, error) {
	apiURL := fmt.Sprintf("https://v6.exchangerate-api.com/v6/e42998891b496bbfa0d65b81/latest/%s", from)
	resp, err := http.Get(apiURL)
	if err != nil {
		return 0, 0, fmt.Errorf("failed to call API: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return 0, 0, fmt.Errorf("API error: %s", string(body))
	}

	var data ExchangeAPIResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return 0, 0, fmt.Errorf("failed to decode JSON: %v", err)
	}

	// Ambil rate dari map
	rate, ok := data.ConversionRates[to]
	if !ok {
		return 0, 0, fmt.Errorf("currency %s not found", to)
	}

	result := amount * rate
	fmt.Printf("✅ %s -> %s | rate: %.2f | result: %.2f\n", from, to, rate, result)
	return rate, result, nil
}

func handler(w http.ResponseWriter, r *http.Request) {
	from := r.URL.Query().Get("from")
	to := r.URL.Query().Get("to")
	amountStr := r.URL.Query().Get("amount")

	if from == "" || to == "" || amountStr == "" {
		http.Error(w, "Missing query parameters", http.StatusBadRequest)
		return
	}

	amount, err := strconv.ParseFloat(amountStr, 64)
	if err != nil {
		http.Error(w, "Invalid amount", http.StatusBadRequest)
		return
	}

	rate, result, err := convertCurrency(from, to, amount)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"from":   from,
		"to":     to,
		"rate":   rate,
		"result": result,
	}

	json.NewEncoder(w).Encode(response)
}

func main() {
	http.HandleFunc("/convert", handler)
	fmt.Println("🚀 Server running at http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
