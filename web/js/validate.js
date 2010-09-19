<!-- Original:  Ronnie T. Moore -->
<!-- Web Site:  The JavaScript Source -->
    
<!-- Dynamic 'fix' by: Nannette Thacker -->
<!-- Web Site: http://www.shiningstar.net -->
    
<!-- This script and many more are available free online at -->
<!-- The JavaScript Source!! http://javascript.internet.com -->
    
function text_counter(field, countfield, maxlimit) {
    if (field.val().length > maxlimit) {
        field.attr( 'value', field.val().substring(0, maxlimit) );
    }
    else {
        countfield.attr('value', maxlimit - field.val().length );
    }
}
