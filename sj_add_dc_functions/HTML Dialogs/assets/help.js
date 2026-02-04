/**
 * Add DC Functions plugin for SketchUp.
 */

// Espace de noms de l'auteur.
const SimJoubert = {}

/**
 * Retrouve l'élément représentant une fonction via son nom.
 * 
 * @param {string} functionName 
 * @returns {HTMLElement}
 */
SimJoubert.getFunctionByName = functionName => {
    return document.querySelector('.sj-function[data-function-name=' + functionName + ']')
}

/**
 * Met en surbrillance puis copie le texte contenu dans un élément.
 * 
 * @param {HTMLElement} element 
 */
SimJoubert.highlightAndCopy = element => {
    const selection = window.getSelection()
    const range = document.createRange()
    range.selectNodeContents(element)
    selection.removeAllRanges()
    selection.addRange(range)
    // TODO: Utiliser l'API Clipboard en priorité si elle est disponible.
    document.execCommand('copy')
}

/**
 * Fonction appelée lors d'un clic sur un bouton "∨" ou "∧".
 */
SimJoubert.onExpandButtonClick = event => {
    const functionName = event.currentTarget.dataset.functionName // Cf. data-function-name
    SimJoubert.getFunctionByName(functionName).classList.toggle('expanded')
}

/**
 * Fonction appelée lors d'un clic sur un bouton "Copier".
 */
SimJoubert.onCopyButtonClick = event => {
    const functionName = event.currentTarget.dataset.functionName // Cf. data-function-name
    SimJoubert.highlightAndCopy(
        SimJoubert.getFunctionByName(functionName).querySelector('.sj-function-signature')
    )
}

/**
 * Ajoute des écouteurs d'évènements sur les différents types de boutons.
 */
SimJoubert.addEventListeners = () => {
    document.querySelectorAll('.sj-expand-function-button').forEach(expandButton => {
        expandButton.addEventListener('click', SimJoubert.onExpandButtonClick)
    })
    document.querySelectorAll('.sj-copy-function-button').forEach(copyButton => {
        copyButton.addEventListener('click', SimJoubert.onCopyButtonClick)
    })
}

// Dès que le document HTML est chargé :
document.addEventListener('DOMContentLoaded', _event => {
    SimJoubert.addEventListeners()
})
