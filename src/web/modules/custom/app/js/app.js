var App = React.createClass({
  render: function() {
    return (
      <Quizzes/>
    )
  }
});

var Quizzes = React.createClass({
  getInitialState: function() {
    return {
      quizzes: [],
      quiz: null
    }
  },

  componentDidMount: function() {
    var that = this;

    this.quizzes = axios({
      method:'get',
      url:'/api/v1',
      responseType:'stream'
    }).then(function(result) {
      that.setState({
        quizzes: result.data
      });
    });
  },

  componentWillUnmount: function() {
    this.quizzes.abort();
  },

  takeQuiz: function (item) {
    this.setState({
      quiz: item
    });
  },

  render: function() {
    var that = this;

    return (
      <div>
        <h2>Quizzes!</h2>
        {this.state.quizzes.map(function(item) {
          return (
            <div key={item.nid[0].value} className="job">
              <a href="javascript:void();" onClick={that.takeQuiz.bind(that, item)}>Take the <strong>{item.title[0].value}</strong> quiz!</a>
            </div>
          );
        })}

        {this.state.quiz ? <Quiz item={this.state.quiz} /> : <p><hr/>Select a quiz from above</p>}
      </div>
    )
  }
});

var Quiz = React.createClass({
  componentDidMount() {
    this.handleSlickQuiz();
  },

  componentDidUpdate() {
    this.handleSlickQuiz();
  },

  handleSlickQuiz() {
    var el = $(this.refs.quizwrapper);
    var questions = JSON.parse(this.props.item.field_quiz[0].value) || {};

    questions.info.name=this.props.item.title[0].value;
    questions.info.main="";
    questions.info.results="Quiz results";

    el.html('<div id="slickQuiz"><h1 class="quizName"></h1><div class="quizArea"><div class="quizHeader"><a class="startQuiz" href="#">Get Started!</a></div></div><div class="quizResults"><h3 class="quizScore">You Scored: <span></span></h3><h3 class="quizLevel"><strong>Ranking:</strong> <span></span></h3><div class="quizResultsCopy"></div></div></div>');

    $('#slickQuiz').slickQuiz({
      json: questions,
      skipStartButton: true
    });
  },

  render: function() {
    if (!this.props.item)
      return false;

    return (
      <div>
        <hr/>
        <div ref="quizwrapper">
        </div>
      </div>
    );
  }
});


ReactDOM.render(<App />, document.querySelector('#app'));
