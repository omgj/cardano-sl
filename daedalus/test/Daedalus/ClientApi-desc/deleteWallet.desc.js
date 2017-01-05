import {assert} from 'chai';
import sinon from 'sinon';

const Daedalus = require ('../../../dist/Daedalus');

export default function () {

  describe('deleteWallet()', () => {

    let xhr;
    let requests;

    beforeEach(() => {
      requests = [];
      xhr = sinon.useFakeXMLHttpRequest();
      xhr.onCreate = (req) => requests.push(req);
    })

    afterEach(() => xhr.restore())

    it('returns empty object', (done) => {
      const response = {
        Right:[]
      };

      Daedalus.ClientApi.deleteWallet('123')()
        .then( (result) => {
          assert.deepEqual(result, {}, '"unit" as a return value');
          done();
        }, (error) => done(error))
        .catch(done);

      requests[0]
        .respond(200,
          { "Content-Type": "application/json" },
          JSON.stringify(response)
      );
    })

    it('returns a HTTPStatusError if server returns "400"', (done) => {

      Daedalus.ClientApi.deleteWallet('not-exist')()
        .then( (result) => done(),
          (error) => {
            assert.include(error.message, 'HTTPStatusError',
            'includes HTTPStatusError error message');
            done();
        })
        .catch(done);

      requests[0]
        .respond(400,
          { "Content-Type": "application/json" }
      );
    })

    it('rejects with a ServerError if server response with Left', (done) => {
      const response = { Left: "Any error" }
      Daedalus.ClientApi.deleteWallet('')()
        .then( (result) => done(),
          (error) => {
            assert.include(error.message, 'ServerError', 'ServerError error message');
            done();
        })
        .catch(done);

      requests[0].respond(200,
        {"Content-Type": "application/json"},
        JSON.stringify(response)
      );
    })

  })
}
