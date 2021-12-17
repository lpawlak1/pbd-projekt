---
fontfamily: helvet
header-includes:
  - \renewcommand{\familydefault}{\sfdefault}
geometry: margin=2cm
documentclass: extarticle
<!-- fontsize: 14pt -->
---

# Projekt bazy danych "SouthWind" do restauracji

## Autorzy

- Łukasz Pawlak
- Jakub Stępień
- Piotr Witek


# Wymagania funkcjonalne

## Wymagania ze strony restuaracji

- dodanie nowego klienta - system umożliwia ręczne dodanie klienta do bazy przez pracownika firmy

### Potrawy

- dodanie nowej potrawy do bazy wszystkich potraw
- dana potrawa jest oznaczana jako niedostępna

#### Owoce morza

- sprawdzenie czy data zamówienia jest odpowiednia
- czy jest odpowiedni dzień
  -  W dniach czwartek-piątek-sobota istnieje możliwość wcześniejszego zamówienia dań zawierających owoce morza.
      Z uwagi na indywidualny import takie zamówienie winno być złożone maksymalnie do poniedziałku
      poprzedzającego zamówienie.

### Menu

- dodanie potrawy do menu
    - przy próbie dodania potrawy do menu sprawdzane jest czy potrawa nie znajduje się obecnie w menu oraz czy wycofano potrawę co najmniej 2 tygodnie wcześniej
- wycofanie potrawy z menu
    - data wycofania potrawy ustawiana jest na aktualną
- zwracanie listy potraw w obecnym menu
    - zwracana jest lista pozycji menu, które mają datę pustą lub większą niż dzisiejsza
- informowanie o konieczności zmian w menu
    - jeśli liczba pozycji menu, których data dodania do menu jest mniejsza lub równa od
    obecnej daty pomniejszonej o 14 dni zwracana jest informacja o konieczności
    zmiany menu

### Rezerwacje

- dodanie nowego stolika do bazy stolików
- zwrócenie wolnych stolików w danym terminie
    - w celu otrzymania numerów oraz liczby miejsc wolnych stolików posługujemy się dwiema wartościami:
      - 1. data zajęcia
      - 2. data zwolnienia
      - Jeżeli stolik jest wolny to:
        - 1. Data zajęcia i zwolnienia nie są zdefiniowane lub
        - 2. Data zajęcia jest większa od zadanego terminu, a data zwolnienia jest mniejsza od zadanego terminu.
- kontrola dostępności stolików przy dokonywaniu rezerwacji
    - przy dokonywaniu rezerwacji sprawdzana jest dostępność stolików w danym
        terminie w sposób jak powyżej z dodatkowym warunkiem sprawdzającym czy
        sumaryczna liczba miejsc przy wolnych stolikach jest większa lub równa ilości osób
        w rezerwacji
- oznaczenie stolika jako wolny / zajęty (zapisywana jest odpowiednio data
    zwolnienia / zajęcia stolika)
- zmiana statusu rezerwacji klienta indywidualnego, w tym możliwość odrzucenia rezerwacji:
    - po dokonaniu rezerwacji przez klienta za pomocą formularza www zostaje ona
        oznaczona automatycznie jako niepotwierdzona, pracownik restauracji może
        potwierdzić lub odrzucić rezerwację
    - potwierdzoną rezerwację pracownik może anulować z powodu np.nieprawidłowego statusu opłacenia zamówienia lub na
        życzenie klienta

### Zamówienia

- zamówienie może być utworzone dla klienta zarejestrowanego w systemie
    do bazy zamówień dodawane jest nowe zamówienie zawierające wybrane z
    obecnego menu potrawy, obecną datę jako datę zamówienia, jeżeli zamówienie jest
    na wynos to zawiera także datę odbioru, jeżeli zamówienie jest na miejscu to wtedy
    zawiera także stolik
- jeśli zamówienie obejmuje potrawy zawierające owoce morza, to data realizacji
    zamówienia może wypadać tylko w czwartek, piątek lub sobotę, przy czym data
    zamówienia musi być najpóźniej poniedziałkiem poprzedzającym datę realizacji
    (czyli datę rezerwacji dla zamówień na miejscu lub datę odbioru dla zamówień na
    wynos)

### Rabaty

1. `typ 1` - Po realizacji ustalonej liczby zamówień Z1 (przykładowo Z1=10) za co najmniej określoną kwotę K1 (np. 30 zł każde zamówienie): R1% (np. 3%) zniżki na wszystkie zamówienia;
2. `typ 2` - Po realizacji zamówień za łączną kwotę K2 (np. 1000 zł): jednorazowa zniżka R2% (np. 5%) na zamówienia złożone przez D1 dni (np. D1 = 7), począwszy od dnia przyznania zniżki (zniżki nie łączą się).

- Dodanie/ usunięcie rabatu
  - Usuwanie rabatu `typ 2` po określonym czasie (D1)
- Trigger na dodanie zamówienia (ilość zamówień `typ 1` / kwota `typ 2`)
- Zdecydowanie która zniżka jest ważniejsza w hierarchii i wybranie jej
- zapisanie informacji o rabacie przyznanym danemu klientowi
- obliczenie rabatu dla danego klienta w trakcie składania zamówienia
- zmiana statusu opłacenia zamówienia

### Raporty

- generowanie listy potraw do przygotowania w danym czasie
    - zwracana jest lista potraw wraz z ilością dla zamówień których data złożenia (w
    przypadku zamówień na wynos składanych zdalnie data odbioru pomniejszona o
    pewien określony czas przygotowania, w przypadku zamówień składanych przez
    internet data rezerwacji stolika tylko dla potwierdzonych rezerwacji) mieści się w
    zadanym przedziale czasowym
- generowanie raportów (miesięcznych i tygodniowych dotyczących rezerwacji stolików, rabatów, menu)
- generowanie statystyk dla klientów indywidualnych oraz firm dotyczących kwot oraz czasu składania zamówień
- generowanie raportów dotyczących zamówień oraz rabatów dla klienta indywidualnego oraz firm
- generowanie faktury za zamówienie dla firmy

## Wymagania ze strony klientów

### Rezerwacje

- dokonywanie rezerwacji stolika
    - sprawdzana jest dostępność stolików w zadanym terminie,
        sprawdzane są uprawnienia klienta do dokonywania rezerwacji online (czy
        dokonano wcześniej odpowiedniej liczby zamówień na odpowiednią kwotę rezerwacji mogą dokonywać tylko zarejestrowani użytkownicy)
    - jeżeli klientem jest firma ma możliwość złożenia rezerwacji imiennie lub na firme,
    - w przypadku rezerwacji imiennej przez firmę dodawane są imiona i nazwiska osób
    - w przypadku rezerwacji przez klienta indywidualnego dodawane jest zamówienie
    - rezerwacja musi być potwierdzona przez pracownika restauracji
    - jeśli pracownik odrzuci rezerwacje usuwane jest zamówienie z nią powiązane
- składanie zamówień na wynos
    - klient wprowadza wszystkie dane wymagane do złożenia zamówienia, wybiera potrawy z obecnie dostępnego menu
- anulowanie rezerwacji
    - rezerwacja zostaje wyszukana na podstawie jej `PrimaryKey` a następnie jej status zostaje zmieniony na `anulowana przez klienta`.
- `?forma rozliczenia, gdzy kupuje firma?`
