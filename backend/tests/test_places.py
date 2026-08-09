def test_mock_autocomplete_supplies_frontend_search_suggestions(client):
    response = client.post("/api/places/autocomplete", json={"query": "Flinders"})
    body = response.get_json()

    assert response.status_code == 200
    assert body["metadata"]["data_mode"] == "mock"
    assert body["suggestions"][0]["description"].startswith("Growth Factory")


def test_mock_autocomplete_includes_freddys_default_addresses(client):
    home = client.post("/api/places/autocomplete", json={"query": "Pearl River"}).get_json()
    work = client.post("/api/places/autocomplete", json={"query": "Growth Factory"}).get_json()

    assert home["suggestions"][0]["description"].startswith("903/8 Pearl River Rd")
    assert work["suggestions"][0]["description"].startswith("Growth Factory")


def test_autocomplete_rejects_too_short_query(client):
    response = client.post("/api/places/autocomplete", json={"query": "F"})

    assert response.status_code == 400
    assert response.get_json()["error"]["details"]["field"] == "query"
