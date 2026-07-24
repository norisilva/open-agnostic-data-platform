package apicurio

import (
	"fmt"
	"io"
	"net/http"
)

type Client struct {
	baseURL    string
	httpClient *http.Client
}

func NewClient(baseURL string) *Client {
	return &Client{
		baseURL:    baseURL,
		httpClient: &http.Client{},
	}
}

func (c *Client) GetSchema(group, artifactId string) (string, error) {
	// Apicurio 3.x API for latest artifact version
	url := fmt.Sprintf("%s/apis/registry/v3/groups/%s/artifacts/%s/versions/branch=latest", c.baseURL, group, artifactId)

	resp, err := c.httpClient.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("apicurio returned status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(body), nil
}
