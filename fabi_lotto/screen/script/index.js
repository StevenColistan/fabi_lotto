window.addEventListener('message', (event) => {
    if (event.data.action === 'openLottoUI') {
        if(event.data.show) {
            $('body').show();
            $('.bg-white').show();
        } else {
            $('body').hide();
            $('.bg-white').hide();
        } 
    } if (event.data.action === 'updateJackpot') {
        $('.bg-green-500').html(`Jackpot: ${event.data.jackpot}`);
        console.log("jackpotElement", event.data.jackpot);
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        $('body').hide();
        $('.bg-white').hide();
        $.post('https://fabi_lotto/closeLottoUI', JSON.stringify({}));
    }
});

let selectedNumbers = [];

function lotto(numbers) {
    const index = selectedNumbers.indexOf(numbers);
    if (index > -1) {
        selectedNumbers.splice(index, 1);
    } else if (selectedNumbers.length < 3) {
        selectedNumbers.push(numbers);
    }
    updateSelection();
}

function updateSelection() {
    const buttons = document.querySelectorAll('.grid button');
    buttons.forEach(button => {
        if (selectedNumbers.includes(button.innerText)) {
            button.classList.add('bg-blue-500', 'text-white');
            button.classList.remove('bg-gray-200', 'text-gray-900');
        } else {
            button.classList.remove('bg-blue-500', 'text-white');
            button.classList.add('bg-gray-200', 'text-gray-900');
        }
    });
}

function submitNumbers() {
    if (selectedNumbers.length === 3) {
        console.log("selectedNumbers", selectedNumbers);
        $.post(
            'https://fabi_lotto/chooseLottoNumbers',
            JSON.stringify({
                numbers: selectedNumbers
            })
        ).catch(error => {
            console.error('Error:', error);
        });
    } else {
        alert('Bitte wählen Sie genau 3 Zahlen aus.');
    }
}